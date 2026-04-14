// UI guideline: central place for colors, TextField and Dropdown styles.

import 'package:flutter/material.dart';

/// App colors used across all screens (login, map, reservations, QR scanner).
abstract final class AppColors {
  // Accent yellow (login bg, map "Skanuj", QR FAB)
  static const Color accentYellow = Color(0xFFFFDE00);
  static const Color accentYellowDark = Color(0xFFFDCB21);

  // Dark theme (QR scanner)
  static const Color darkBackground = Color(0xFF1E212D);
  static const Color darkButtonBg = Color(0xFF2C2F36);
  static const Color darkSecondaryBg = Color(0xFF4A4F5B);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textPlaceholder = Color(0xFFA0A0A0);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFF000000);

  // Surfaces
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color reservationSlotGreen = Color(0xFF6BD96B);

  // Shadows / borders
  static const Color shadowLight = Color(0x1A000000);
  static const Color borderLight = Color(0xFFE0E0E0);
}

/// Input and dropdown styles (light and dark variants).
abstract final class AppInputStyles {
  static const double _radius = 14.0;
  static const double _radiusLarge = 25.0;

  /// TextField decoration for light screens (map, login).
  static InputDecoration lightInputDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: AppColors.textPlaceholder,
        fontWeight: FontWeight.normal,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surfaceWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: AppColors.accentYellow, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  /// TextField decoration for dark screen (QR scanner).
  static InputDecoration darkInputDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: AppColors.textPlaceholder,
        fontWeight: FontWeight.normal,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.darkSecondaryBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: AppColors.accentYellowDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  /// Border radius for search bar / pill-shaped inputs.
  static BorderRadius get searchBarRadius =>
      BorderRadius.circular(_radiusLarge);

  /// Dropdown: same family as TextField (light).
  static InputDecoration lightDropdownDecoration({
    String? hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: AppColors.textPlaceholder,
        fontWeight: FontWeight.normal,
      ),
      filled: true,
      fillColor: AppColors.surfaceWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: AppColors.accentYellow, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  /// Dropdown: dark variant.
  static InputDecoration darkDropdownDecoration({
    String? hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: AppColors.textPlaceholder,
        fontWeight: FontWeight.normal,
      ),
      filled: true,
      fillColor: AppColors.darkSecondaryBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: AppColors.accentYellowDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

/// ThemeData for MaterialApp (UI guideline).
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentYellow,
          primary: AppColors.accentYellow,
          surface: AppColors.surfaceWhite,
          onPrimary: AppColors.textOnAccent,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
        ),
        scaffoldBackgroundColor: AppColors.surfaceWhite,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.accentYellow, width: 2),
          ),
          hintStyle: const TextStyle(
            color: AppColors.textPlaceholder,
            fontWeight: FontWeight.normal,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surfaceWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.accentYellow, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textSecondary),
          labelLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
