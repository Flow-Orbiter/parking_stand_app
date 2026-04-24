import 'package:flutter/material.dart';
import 'package:mdm_sport/l10n/app_localizations.dart' show L10nScope;
import 'package:mdm_sport/l10n/translations.dart';
import 'package:mdm_sport/theme/app_theme.dart';

/// Przełącznik PL/EN — wariant [login] (jasny tekst na tle zdjęcia) lub [drawer] (na jasnym tle).
enum LanguagePickerChipsStyle { login, drawer }

class LanguagePickerChips extends StatelessWidget {
  const LanguagePickerChips({
    super.key,
    required this.style,
  });

  final LanguagePickerChipsStyle style;

  @override
  Widget build(BuildContext context) {
    final l10n = L10nScope.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LanguageChip(
          style: style,
          label: l10n.t(AppStrings.loginLanguagePl),
          isSelected: l10n.locale == 'pl',
          onTap: () => l10n.onLocaleChanged('pl'),
          flagPainter: const _PolishFlagPainter(),
        ),
        const SizedBox(width: 12),
        _LanguageChip(
          style: style,
          label: l10n.t(AppStrings.loginLanguageEn),
          isSelected: l10n.locale == 'en',
          onTap: () => l10n.onLocaleChanged('en'),
          flagPainter: const _EnglishFlagPainter(),
        ),
      ],
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.style,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.flagPainter,
  });

  final LanguagePickerChipsStyle style;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final CustomPainter flagPainter;

  @override
  Widget build(BuildContext context) {
    final login = style == LanguagePickerChipsStyle.login;
    final color = login ? Colors.white : AppColors.textPrimary;
    return Material(
      color: login
          ? Colors.white.withValues(alpha: isSelected ? 0.25 : 0.1)
          : (isSelected
              ? AppColors.accentYellow.withValues(alpha: 0.45)
              : const Color(0xFFF0F0F0)),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 18,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: login ? Colors.white : AppColors.borderLight,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: CustomPaint(painter: flagPainter),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolishFlagPainter extends CustomPainter {
  const _PolishFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height / 2;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, h),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h, size.width, h),
      Paint()..color = Colors.red,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EnglishFlagPainter extends CustomPainter {
  const _EnglishFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF012169),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
