import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mdm_sport/auth/auth_service.dart';
import 'package:mdm_sport/l10n/app_localizations.dart' show L10nScope;
import 'package:mdm_sport/l10n/translations.dart';
import 'package:mdm_sport/theme/app_theme.dart';
import 'package:mdm_sport/util/phone_e164_pl.dart';
import 'package:mdm_sport/util/app_links.dart';
import 'package:mdm_sport/widgets/language_picker_chips.dart';

/// Ekran wymuszenia podpięcia / weryfikacji numeru (OAuth bez telefonu).
class PhoneVerificationRequiredScreen extends StatefulWidget {
  const PhoneVerificationRequiredScreen({super.key});

  @override
  State<PhoneVerificationRequiredScreen> createState() =>
      _PhoneVerificationRequiredScreenState();
}

class _PhoneVerificationRequiredScreenState
    extends State<PhoneVerificationRequiredScreen> {
  final _auth = AuthService();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _verificationId;
  bool _busy = false;
  bool _codeSent = false;

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
    if (!isValidE164(phone)) {
      _showError(L10nScope.of(context).t(AppStrings.loginPhoneInvalid));
      return;
    }
    _setBusy(true);
    try {
      await _auth.startPhoneLogin(
        phone,
        onCodeSent: (vid) {
          if (!mounted) return;
          setState(() {
            _verificationId = vid;
            _codeSent = true;
          });
        },
        onError: (e) {
          if (mounted) _showError(e);
        },
      );
    } catch (e) {
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
      await _auth.confirmPhoneCode(
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

  Future<void> _signOut() async {
    _setBusy(true);
    try {
      await _auth.signOut();
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      _setBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10nScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LanguagePickerChips(style: LanguagePickerChipsStyle.drawer),
              const SizedBox(height: 20),
              Text(
                l10n.t(AppStrings.phoneRequiredTitle),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.t(AppStrings.phoneRequiredBody),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(20),
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
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _phoneController,
                              enabled: !_codeSent,
                              keyboardType: TextInputType.phone,
                              autofillHints: const [AutofillHints.telephoneNumber],
                              inputFormatters: [PlPhoneE164InputFormatter()],
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                labelText: l10n.t(AppStrings.loginPhoneTitle),
                                hintText: l10n.t(AppStrings.loginPhoneHint),
                                hintStyle: const TextStyle(color: AppColors.textPlaceholder),
                                filled: true,
                                fillColor: const Color(0xFFF2F2F2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.textPlaceholder.withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.accentYellowDark,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _codeSent ? null : _sendSms,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accentYellowDark,
                                foregroundColor: AppColors.textOnAccent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                l10n.t(AppStrings.loginPhoneSendCode),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (_codeSent) ...[
                              const SizedBox(height: 16),
                              TextField(
                                controller: _codeController,
                                keyboardType: TextInputType.number,
                                autofillHints: const [AutofillHints.oneTimeCode],
                                maxLength: 8,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  letterSpacing: 4,
                                ),
                                decoration: InputDecoration(
                                  hintText: l10n.t(AppStrings.loginPhoneCodeHint),
                                  hintStyle: const TextStyle(color: AppColors.textPlaceholder),
                                  filled: true,
                                  fillColor: const Color(0xFFF2F2F2),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppColors.textPlaceholder.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.accentYellowDark,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
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
                                  l10n.t(AppStrings.phoneRequiredSubmit),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _busy ? null : _signOut,
                child: Text(
                  l10n.t(AppStrings.phoneRequiredSignOut),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Center(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
