import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mdm_sport/data/firebase/user_firestore.dart';
import 'package:mdm_sport/l10n/app_localizations.dart' show L10nScope;
import 'package:mdm_sport/l10n/translations.dart';
import 'package:mdm_sport/theme/app_theme.dart';

/// Pierwsze uzupełnienie profilu (imię, opcjonalny e-mail kontaktowy).
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _repo = UserFirestoreRepository();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = FirebaseAuth.instance.currentUser;
    if (u?.displayName != null && u!.displayName!.trim().isNotEmpty) {
      _nameController.text = u.displayName!.trim();
    }
    if (u?.email != null && u!.email!.trim().isNotEmpty) {
      _emailController.text = u.email!.trim();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  static final _emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> _save() async {
    final l10n = L10nScope.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t(AppStrings.profileSetupNameError))),
      );
      return;
    }
    final extra = _emailController.text.trim();
    if (extra.isNotEmpty && !_emailOk.hasMatch(extra)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t(AppStrings.profileSetupEmailError))),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      await _repo.completeProfile(
        user,
        displayName: name,
        contactEmail: extra.isEmpty ? null : extra,
      );
      if (mounted) widget.onCompleted();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10nScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t(AppStrings.profileSetupTitle)),
        backgroundColor: AppColors.accentYellow,
        foregroundColor: AppColors.textOnAccent,
        automaticallyImplyLeading: false,
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.t(AppStrings.profileSetupSubtitle),
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    decoration: AppInputStyles.lightInputDecoration().copyWith(
                      labelText: l10n.t(AppStrings.profileSetupNameLabel),
                      hintText: l10n.t(AppStrings.profileSetupNameHint),
                      fillColor: const Color(0xFFF2F2F2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    decoration: AppInputStyles.lightInputDecoration().copyWith(
                      labelText: l10n.t(AppStrings.profileSetupEmailLabel),
                      hintText: l10n.t(AppStrings.profileSetupEmailHint),
                      fillColor: const Color(0xFFF2F2F2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentYellowDark,
                      foregroundColor: AppColors.textOnAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      l10n.t(AppStrings.profileSetupSave),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
