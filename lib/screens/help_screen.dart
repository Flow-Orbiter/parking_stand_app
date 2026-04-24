import 'package:flutter/material.dart';
import 'package:mdm_sport/l10n/app_localizations.dart' show L10nScope;
import 'package:mdm_sport/l10n/translations.dart';
import 'package:mdm_sport/theme/app_theme.dart';
import 'package:mdm_sport/util/app_links.dart';

/// Kontakt do zgłaszania problemów (tel. + e-mail) oraz polityka prywatności.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static final Uri _telUri = Uri.parse('tel:+48607869986');
  static final Uri _mailtoUri = Uri(
    scheme: 'mailto',
    path: 'biuro@mdm-electronic.com',
  );

  @override
  Widget build(BuildContext context) {
    final l10n = L10nScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t(AppStrings.mapDrawerHelp)),
        backgroundColor: AppColors.accentYellow,
        foregroundColor: AppColors.textOnAccent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.t(AppStrings.legalPrivacyPolicy),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () => launchExternalUrl(context, kPrivacyPolicyUri),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.language, color: AppColors.textPrimary, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.t(AppStrings.helpPrivacySiteLabel),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(Icons.open_in_new, size: 20, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.t(AppStrings.mapHelpReportTitle),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () => launchExternalUrl(context, _telUri),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.phone, color: AppColors.textPrimary, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t(AppStrings.mapDrawerPhone),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.t(AppStrings.helpReportPhone),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textPlaceholder),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () => launchExternalUrl(context, _mailtoUri),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, color: AppColors.textPrimary, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t(AppStrings.mapDrawerEmail),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.t(AppStrings.helpReportEmail),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textPlaceholder),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
