import 'package:flutter/material.dart';

/// Direct port of `src/theme/theme.ts`.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF06C999);
  static const primaryDark = Color(0xFF048F6E);
  static const secondary = Color(0xFF064E40);
  static const tertiary = Color(0xFFD6F5EC);
  static const background = Color(0xFFF7F9F8);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF0E1F1A);
  static const muted = Color(0xFFF0F2F1);
  static const mutedForeground = Color(0xFF606160);
  static const border = Color(0xFFE0E3E1);
  static const success = Color(0xFF06C999);
  static const warning = Color(0xFFE8A000);
  static const destructive = Color(0xFFD13232);

  // Extra literal colors used ad-hoc across screens (kept named for reuse).
  static const affirmationBg = Color(0xFF0A4A3C);
  static const calmBannerBg = Color(0xFFD1F4EA);
  static const urgentBg = Color(0xFFFDECEC);
  static const urgentBorder = Color(0xFFF8B4B4);
  static const quickActionBg = Color(0xFFE4F8F1);
  static const quickActionBorder = Color(0xFFC3EBE0);
}

class AppTypography {
  AppTypography._();

  static const fontFamily =
      null; // System font, matches RN `fontFamily: 'System'`
  static const displayFont = null;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.04),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
      ];

  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.06),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
      ];

  static List<BoxShadow> get glow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.45),
          offset: const Offset(0, 6),
          blurRadius: 20,
        ),
      ];
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: AppTypography.fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.card,
      error: AppColors.destructive,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.tertiary,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
