import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mdm_sport/debug_agent_log.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Logowanie Firebase: telefon (SMS), Google, Apple.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _injected = auth;

  final FirebaseAuth? _injected;
  bool _googleInitialized = false;

  FirebaseAuth get _a => _injected ?? FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _a.authStateChanges();

  User? get currentUser => _a.currentUser;

  Future<void> _ensureGoogleSignIn() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  Future<void> signOut() async {
    if (_googleInitialized) {
      await GoogleSignIn.instance.signOut();
    }
    await _a.signOut();
  }

  /// [phoneE164] np. +48123456789. Na Androidzie (niektóre urządzenia) SMS może się zalogować automatycznie.
  /// Gdy użytkownik jest zalogowany (np. Google) bez telefonu, credential jest łączony z kontem.
  Future<void> startPhoneLogin(
    String phoneE164, {
    required void Function(String verificationId) onCodeSent,
    required void Function(Object e) onError,
  }) async {
    // #region agent log
    debugAgentLog('H2', 'auth_service.dart:startPhoneLogin', 'before verifyPhoneNumber', {
      'e164Len': phoneE164.length,
    });
    // #endregion
    await _a.verifyPhoneNumber(
      phoneNumber: phoneE164,
      timeout: const Duration(seconds: 90),
      verificationCompleted: (PhoneAuthCredential credential) async {
        final u = _a.currentUser;
        // #region agent log
        String branch = 'noop';
        if (u != null && (u.phoneNumber == null || u.phoneNumber!.isEmpty)) {
          branch = 'link';
        } else if (u == null) {
          branch = 'signIn';
        }
        debugAgentLog('H5', 'auth_service.dart:verificationCompleted', 'enter', {
          'branch': branch,
          'hasUser': u != null,
        });
        // #endregion
        try {
          if (u != null && (u.phoneNumber == null || u.phoneNumber!.isEmpty)) {
            await u.linkWithCredential(credential);
            await u.reload();
          } else if (u == null) {
            await _a.signInWithCredential(credential);
            await _a.currentUser?.reload();
          }
          // #region agent log
          debugAgentLog('H5', 'auth_service.dart:verificationCompleted', 'after auth ok', {
            'branch': branch,
          });
          // #endregion
        } on FirebaseAuthException catch (e) {
          // #region agent log
          debugAgentLog('H3', 'auth_service.dart:verificationCompleted', 'FAE', {
            'code': e.code,
          });
          // #endregion
          onError(e);
        } catch (e, st) {
          debugPrint('startPhoneLogin verificationCompleted: $e\n$st');
          // #region agent log
          debugAgentLog('H3', 'auth_service.dart:verificationCompleted', 'non-FAE', {
            'type': e.runtimeType.toString(),
          });
          // #endregion
          onError(e);
        }
      },
      verificationFailed: (e) {
        // #region agent log
        debugAgentLog('H3', 'auth_service.dart:verificationFailed', e.code, {
          'msgLen': (e.message ?? '').length,
        });
        // #endregion
        onError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        // #region agent log
        debugAgentLog('H4', 'auth_service.dart:codeSent', 'fired', {
          'vidLen': verificationId.length,
        });
        // #endregion
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {
        // #region agent log
        debugAgentLog('H2', 'auth_service.dart:codeAutoRetrievalTimeout', 'fired', {});
        // #endregion
      },
    );
    // #region agent log
    debugAgentLog('H2', 'auth_service.dart:startPhoneLogin', 'after verifyPhoneNumber returned', {});
    // #endregion
  }

  /// Logowanie samym numerem albo [linkWithCredential], jeśli sesja (OAuth) już trwa.
  Future<void> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    final u = _a.currentUser;
    if (u != null && (u.phoneNumber == null || u.phoneNumber!.isEmpty)) {
      await u.linkWithCredential(credential);
      await u.reload();
    } else {
      await _a.signInWithCredential(credential);
      await _a.currentUser?.reload();
    }
  }

  Future<void> signInWithGoogle() async {
    await _ensureGoogleSignIn();
    final account = await GoogleSignIn.instance.authenticate(
      scopeHint: const <String>['email', 'profile'],
    );
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-id-token-null',
        message: 'Brak idToken z Google',
      );
    }
    String? accessToken;
    try {
      final authz = await account.authorizationClient.authorizeScopes(
        const <String>['email', 'profile'],
      );
      accessToken = authz.accessToken;
    } catch (_) {
      // Firebase często wystarczy sam idToken
    }
    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );
    await _a.signInWithCredential(credential);
  }

  Future<void> signInWithApple() async {
    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final idToken = apple.identityToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'apple-id-token-null',
        message: 'Brak identityToken z Apple',
      );
    }
    final oauth = OAuthProvider('apple.com');
    final credential = oauth.credential(
      idToken: idToken,
      accessToken: apple.authorizationCode,
    );
    await _a.signInWithCredential(credential);
  }
}
