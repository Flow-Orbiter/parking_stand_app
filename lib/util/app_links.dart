import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mdm_sport/l10n/app_localizations.dart' show L10nScope;
import 'package:mdm_sport/l10n/translations.dart';

/// Strona informacyjna / polityka prywatności (MDM Sport).
final Uri kPrivacyPolicyUri = Uri.parse('https://sport.mdm-electronic.com/');

Future<void> launchExternalUrl(BuildContext context, Uri uri) async {
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!context.mounted || ok) return;
  final l10n = L10nScope.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.t(AppStrings.mapHelpLinkError))),
  );
}
