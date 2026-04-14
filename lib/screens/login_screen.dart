import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:parking_stand_app/l10n/app_localizations.dart';
import 'package:parking_stand_app/l10n/translations.dart';
import 'package:parking_stand_app/theme/app_theme.dart';
import 'package:parking_stand_app/screens/map_screen.dart';

/// URL tła rowerowego (Unsplash, do debugu; później można podmienić na asset).
const String _kLoginBackgroundUrl =
    'https://images.unsplash.com/photo-1571068316344-75bc76f77890?w=800';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LanguageChip(
                        label: L10nScope.of(context).t(AppStrings.loginLanguagePl),
                        isSelected: L10nScope.of(context).locale == 'pl',
                        onTap: () => L10nScope.of(context).onLocaleChanged('pl'),
                        flagPainter: _PolishFlagPainter(),
                      ),
                      const SizedBox(width: 12),
                      _LanguageChip(
                        label: L10nScope.of(context).t(AppStrings.loginLanguageEn),
                        isSelected: L10nScope.of(context).locale == 'en',
                        onTap: () => L10nScope.of(context).onLocaleChanged('en'),
                        flagPainter: _EnglishFlagPainter(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(28),
                    elevation: 2,
                    shadowColor: AppColors.shadowLight,
                    child: InkWell(
                      onTap: () => _navigateToMap(context),
                      borderRadius: BorderRadius.circular(28),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        child: Center(
                          child: Text(
                            L10nScope.of(context).t(AppStrings.loginEnter),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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

  void _navigateToMap(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MapScreen()),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.flagPainter,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final CustomPainter flagPainter;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: isSelected ? 0.25 : 0.1),
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
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: CustomPaint(painter: flagPainter),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
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
