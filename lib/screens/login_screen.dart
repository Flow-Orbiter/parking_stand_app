import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:mdm_sport/auth/auth_service.dart';
import 'package:mdm_sport/l10n/app_localizations.dart' show L10nScope;
import 'package:mdm_sport/l10n/translations.dart';
import 'package:mdm_sport/theme/app_theme.dart';
import 'package:mdm_sport/debug_agent_log.dart';
import 'package:mdm_sport/util/phone_e164_pl.dart';
import 'package:mdm_sport/util/app_links.dart';
import 'package:mdm_sport/widgets/language_picker_chips.dart';
import 'package:mdm_sport/screens/map_screen.dart';

/// URL tła rowerowego (Unsplash; później asset).
const String _kLoginBackgroundUrl =
    'https://images.unsplash.com/photo-1571068316344-75bc76f77890?w=800';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.firebaseEnabled = true});

  final bool firebaseEnabled;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthService? _auth;
  AuthService get _authService {
    if (!widget.firebaseEnabled) {
      throw StateError('AuthService tylko przy włączonym Firebase');
    }
    return _auth ??= AuthService();
  }

  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _verificationId;
  bool _busy = false;
  bool _codeSent = false;
  bool _appleAvailable = false;
  /// false = tryb logowania, true = rejestracja (ten sam przepływ SMS; inny opis w UI).
  bool _authRegister = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      SignInWithApple.isAvailable().then((v) {
        if (mounted) setState(() => _appleAvailable = v);
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _setBusy(bool v) {
    if (mounted) setState(() => _busy = v);
  }

  void _showError(Object e) {
    if (!mounted) return;
    final String msg;
    if (e is FirebaseAuthException) {
      msg = e.message ?? e.code;
    } else if (e is PlatformException) {
      msg = e.message ?? e.code;
    } else {
      msg = e.toString();
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendSms() async {
    final phone = normalizePhoneInputToE164(_phoneController.text);
    // #region agent log
    debugAgentLog('H4', 'login_screen.dart:_sendSms', 'normalized', {
      'e164Len': phone.length,
      'valid': isValidE164(phone),
    });
    // #endregion
    if (!isValidE164(phone)) {
      _showError(L10nScope.of(context).t(AppStrings.loginPhoneInvalid));
      return;
    }
    _setBusy(true);
    try {
      // #region agent log
      debugAgentLog('H2', 'login_screen.dart:_sendSms', 'startPhoneLogin await', {});
      // #endregion
      await _authService.startPhoneLogin(
        phone,
        onCodeSent: (vid) {
          // #region agent log
          debugAgentLog('H4', 'login_screen.dart:onCodeSent', 'callback', {
            'mounted': mounted,
            'vidLen': vid.length,
          });
          // #endregion
          if (!mounted) return;
          setState(() {
            _verificationId = vid;
            _codeSent = true;
          });
        },
        onError: (e) {
          // #region agent log
          debugAgentLog('H3', 'login_screen.dart:onError', e.runtimeType.toString(), {
            'isFae': e is FirebaseAuthException,
          });
          // #endregion
          if (mounted) _showError(e);
        },
      );
      // #region agent log
      debugAgentLog('H2', 'login_screen.dart:_sendSms', 'startPhoneLogin done', {});
      // #endregion
    } catch (e) {
      // #region agent log
      debugAgentLog('H1', 'login_screen.dart:_sendSms', 'catch', {
        'type': e.runtimeType.toString(),
      });
      // #endregion
      if (mounted) _showError(e);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _verifySms() async {
    final vid = _verificationId;
    if (vid == null) {
      _showError(L10nScope.of(context).t(AppStrings.loginPhoneNoCode));
      return;
    }
    _setBusy(true);
    try {
      await _authService.confirmPhoneCode(
        verificationId: vid,
        smsCode: _codeController.text,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(e);
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _google() async {
    _setBusy(true);
    try {
      await _authService.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(e);
    } on PlatformException catch (e) {
      if (mounted) _showError(e);
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _apple() async {
    _setBusy(true);
    try {
      await _authService.signInWithApple();
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(e);
    } on PlatformException catch (e) {
      if (mounted) _showError(e);
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      _setBusy(false);
    }
  }

  void _mapGuest() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10nScope.of(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _kLoginBackgroundUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) => Container(
              color: const Color(0xFF2C3E50),
              child: const Center(
                child: Icon(Icons.directions_bike, size: 120, color: Colors.white54),
              ),
            ),
          ),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LanguagePickerChips(style: LanguagePickerChipsStyle.login),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                      elevation: 2,
                      shadowColor: AppColors.shadowLight,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: _busy
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _buildForm(l10n),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(L10nScope l10n) {
    if (!widget.firebaseEnabled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.t(AppStrings.loginFirebaseMissing),
            style: const TextStyle(fontSize: 15, height: 1.35),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _mapGuest,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentYellowDark,
              foregroundColor: AppColors.textOnAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              l10n.t(AppStrings.loginEnter),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          _privacyLink(l10n),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment<bool>(
                value: false,
                label: Text(l10n.t(AppStrings.authModeLogin)),
                icon: const Icon(Icons.login, size: 18),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text(l10n.t(AppStrings.authModeRegister)),
                icon: const Icon(Icons.person_add_outlined, size: 18),
              ),
            ],
            selected: {_authRegister},
            onSelectionChanged: (Set<bool> next) {
              if (next.isEmpty) return;
              setState(() => _authRegister = next.contains(true));
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _authRegister
              ? l10n.t(AppStrings.registerPhoneLead)
              : l10n.t(AppStrings.loginPhoneMandatoryInfo),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _authRegister
              ? l10n.t(AppStrings.registerPhoneTitle)
              : l10n.t(AppStrings.loginPhoneTitle),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          enabled: !_codeSent,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          inputFormatters: [PlPhoneE164InputFormatter()],
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: l10n.t(AppStrings.loginPhoneHint),
            hintStyle: const TextStyle(color: AppColors.textPlaceholder),
            filled: true,
            fillColor: const Color(0xFFF2F2F2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textPlaceholder.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textPlaceholder.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accentYellowDark, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: _codeSent ? null : _sendSms,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentYellowDark,
            foregroundColor: AppColors.textOnAccent,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(
            l10n.t(AppStrings.loginPhoneSendCode),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        if (_codeSent) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: 8,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, letterSpacing: 4),
            decoration: InputDecoration(
              hintText: l10n.t(AppStrings.loginPhoneCodeHint),
              hintStyle: const TextStyle(color: AppColors.textPlaceholder),
              filled: true,
              fillColor: const Color(0xFFF2F2F2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.textPlaceholder.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.textPlaceholder.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accentYellowDark, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _verifySms,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              l10n.t(
                _authRegister ? AppStrings.registerPhoneSubmit : AppStrings.loginPhoneVerify,
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.t(AppStrings.loginOrDivider),
                style: const TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _google,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: Color(0xFFDDDDDD)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.g_mobiledata, size: 32),
          label: Text(
            l10n.t(AppStrings.loginWithGoogle),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        if (_appleAvailable) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _apple,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: Color(0xFFDDDDDD)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.apple, size: 24),
            label: Text(
              l10n.t(AppStrings.loginWithApple),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          l10n.t(AppStrings.loginAuxHint),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPlaceholder,
            fontSize: 12,
            height: 1.3,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        _privacyLink(l10n),
      ],
    );
  }

  Widget _privacyLink(L10nScope l10n) {
    return Center(
      child: TextButton(
        onPressed: () => launchExternalUrl(context, kPrivacyPolicyUri),
        child: Text(
          l10n.t(AppStrings.legalPrivacyPolicy),
          style: const TextStyle(
            decoration: TextDecoration.underline,
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
