import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:mdm_sport/auth/auth_service.dart';
import 'package:mdm_sport/data/local/app_storage.dart';
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
  final _codeFocus = FocusNode();
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
    _codeFocus.dispose();
    super.dispose();
  }

  void _setBusy(bool v) {
    if (mounted) setState(() => _busy = v);
  }

  void _resetPhoneFlow() {
    if (!_codeSent && _verificationId == null) return;
    setState(() {
      _codeSent = false;
      _verificationId = null;
      _codeController.clear();
    });
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
    final messenger = ScaffoldMessenger.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        showCloseIcon: true,
        content: Text(
          msg,
          style: const TextStyle(
            fontSize: 15,
            height: 1.35,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _codeFocus.requestFocus();
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.62),
                ],
                stops: const [0.0, 0.42, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: LanguagePickerChips(style: LanguagePickerChipsStyle.login),
                ),
                const SizedBox(height: 8),
                _LoginHero(l10n: l10n),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomInset),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                          child: IntrinsicHeight(
                            child: _LoginSurface(
                              busy: _busy,
                              child: widget.firebaseEnabled
                                  ? _buildForm(l10n)
                                  : _buildFirebaseMissing(l10n),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirebaseMissing(L10nScope l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.t(AppStrings.loginFirebaseMissing),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 15,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
          textAlign: TextAlign.center,
        ),
        if (AppStorage.lastFirebaseInitError != null &&
            AppStorage.lastFirebaseInitError!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.t(AppStrings.loginFirebaseDetailLabel),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                AppStorage.lastFirebaseInitError!,
                style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _mapGuest,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentYellowDark,
            foregroundColor: AppColors.textOnAccent,
            minimumSize: const Size(double.infinity, 52),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  Widget _buildForm(L10nScope l10n) {
    if (!widget.firebaseEnabled) {
      return const SizedBox.shrink();
    }

    final phoneDecoration = AppInputStyles.lightInputDecoration(
      hintText: l10n.t(AppStrings.loginPhoneHint),
      prefixIcon: Icon(
        Icons.phone_iphone_rounded,
        size: 22,
        color: AppColors.textSecondary.withValues(alpha: 0.9),
      ),
    ).copyWith(
      labelText: l10n.t(AppStrings.loginPhoneTitle),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );

    final codeDecoration = AppInputStyles.lightInputDecoration(
      hintText: l10n.t(AppStrings.loginPhoneCodeHint),
      prefixIcon: Icon(
        Icons.sms_outlined,
        size: 22,
        color: AppColors.textSecondary.withValues(alpha: 0.9),
      ),
    ).copyWith(
      labelText: l10n.t(AppStrings.loginPhoneCodeHint),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      counterText: '',
    );

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.standard,
              minimumSize: WidgetStateProperty.all(const Size(0, 48)),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            segments: [
              ButtonSegment<bool>(
                value: false,
                label: Text(l10n.t(AppStrings.authModeLogin)),
                icon: const Icon(Icons.login_rounded, size: 18),
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
          const SizedBox(height: 16),
          Text(
            _authRegister
                ? l10n.t(AppStrings.registerPhoneLead)
                : l10n.t(AppStrings.loginPhoneMandatoryInfo),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _phoneController,
            enabled: !_codeSent,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [PlPhoneE164InputFormatter()],
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            decoration: phoneDecoration,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _codeSent || _busy ? null : _sendSms,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentYellowDark,
              foregroundColor: AppColors.textOnAccent,
              disabledBackgroundColor: AppColors.accentYellowDark.withValues(alpha: 0.45),
              disabledForegroundColor: AppColors.textOnAccent.withValues(alpha: 0.55),
              minimumSize: const Size(double.infinity, 52),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              l10n.t(AppStrings.loginPhoneSendCode),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          if (_codeSent) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy ? null : _resetPhoneFlow,
                child: Text(l10n.t(AppStrings.loginChangePhone)),
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _codeController,
              focusNode: _codeFocus,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 8,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _verifySms(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
              ),
              decoration: codeDecoration,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _verifySms,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                l10n.t(
                  _authRegister ? AppStrings.registerPhoneSubmit : AppStrings.loginPhoneVerify,
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.borderLight)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  l10n.t(AppStrings.loginOrDivider),
                  style: TextStyle(
                    color: AppColors.textPlaceholder.withValues(alpha: 0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.borderLight)),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _busy ? null : _google,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.borderLight),
              minimumSize: const Size(double.infinity, 52),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _GoogleGlyph(),
                const SizedBox(width: 12),
                Text(
                  l10n.t(AppStrings.loginWithGoogle),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (_appleAvailable) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _busy ? null : _apple,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.borderLight),
                minimumSize: const Size(double.infinity, 52),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.apple, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    l10n.t(AppStrings.loginWithApple),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.t(AppStrings.loginAuxHint),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPlaceholder,
                  fontSize: 12,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 8),
          _privacyLink(l10n),
        ],
      ),
    );
  }

  Widget _privacyLink(L10nScope l10n) {
    return Center(
      child: TextButton(
        onPressed: () => launchExternalUrl(context, kPrivacyPolicyUri),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          textStyle: const TextStyle(
            decoration: TextDecoration.underline,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        child: Text(l10n.t(AppStrings.legalPrivacyPolicy)),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero({required this.l10n});

  final L10nScope l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              child: CircleAvatar(
                radius: 44,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.t(AppStrings.appTitle),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.t(AppStrings.loginHeroSubtitle),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _LoginSurface extends StatelessWidget {
  const _LoginSurface({
    required this.busy,
    required this.child,
  });

  final bool busy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
              child: child,
            ),
            if (busy)
              Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.72),
                    child: const Center(
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.accentYellowDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Prosty znak „G” w stylu przycisków Google (bez zewnętrznego assetu).
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderLight),
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4),
          height: 1,
        ),
      ),
    );
  }
}
