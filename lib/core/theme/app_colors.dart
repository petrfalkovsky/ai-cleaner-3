import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Base
  static const Color background = Color(0xFF0A0E27);
  static const Color surface = Color(0x0DFFFFFF); // white 5%
  static const Color surfaceStrong = Color(0x1AFFFFFF); // white 10%
  static const Color border = Color(0x1AFFFFFF); // white 10%

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xCCFFFFFF); // white 80%
  static const Color textTertiary = Color(0x66FFFFFF); // white 40%

  // Accents
  static const Color accentGold = Color(0xFFFFD700);
  static const Color accentOrange = Color(0xFFFFA500);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentPurple = Color(0xFF8B5CF6);

  // White Theme Colors (iPhone Settings style)
  static const Color whiteBackground = Color(0xFFF3F2F8); // iPhone settings background
  static const Color whiteSurface = Colors.white;
  static const Color whiteSurfaceStrong = Color(0x1A000000); // black 10%
  static const Color whiteBorder = Color(0x1A000000); // black 10%
  static const Color whiteTextPrimary = Color(0xFF141414); // черный текст
  static const Color whiteTextSecondary = Color(0xFF818181); // серый текст
  static const Color whiteTextTertiary = Color(0xFF666666);
  static const Color whiteAccentBlue = Color(0xFF1C71FF); // синий акцент
  static const Color whiteAccentRed = Color(0xFFFF3B30); // красный акцент

  // iOS Settings Style Colors - Adaptive (auto dark/light)
  // Light theme colors
  static const Color iosLightBackground = Color(0xFFF2F2F7); // iOS grouped background
  static const Color iosLightSecondaryBackground = Color(0xFFFFFFFF); // iOS cell background
  static const Color iosLightTertiaryBackground = Color(0xFFFFFFFF);
  static const Color iosLightSeparator = Color(0xFFC6C6C8);
  static const Color iosLightLabel = Color(0xFF000000);
  static const Color iosLightSecondaryLabel = Color(0xFF8E8E93);
  static const Color iosLightTertiaryLabel = Color(0xFFC7C7CC);

  // Dark theme colors
  static const Color iosDarkBackground = Color(0xFF000000); // iOS dark grouped background
  static const Color iosDarkSecondaryBackground = Color(0xFF1C1C1E); // iOS dark cell background
  static const Color iosDarkTertiaryBackground = Color(0xFF2C2C2E);
  static const Color iosDarkSeparator = Color(0xFF38383A);
  static const Color iosDarkLabel = Color(0xFFFFFFFF);
  static const Color iosDarkSecondaryLabel = Color(0xFFAEAEB2);
  static const Color iosDarkTertiaryLabel = Color(0xFF48484A);

  // iOS Category Icon Colors
  static const Color categoryRed = Color(0xFFFF3B30);
  static const Color categoryOrange = Color(0xFFFF9500);
  static const Color categoryYellow = Color(0xFFFFCC00);
  static const Color categoryGreen = Color(0xFF34C759);
  static const Color categoryBlue = Color(0xFF007AFF);
  static const Color categoryPurple = Color(0xFFAF52DE);
  static const Color categoryPink = Color(0xFFFF2D55);
  static const Color categoryGray = Color(0xFF8E8E93);

  // iOS UI Constants
  static const double iosContainerRadius = 26.0; // Container corner radius
  static const double iosItemHeight = 68.0; // List item height
}

extension AppColorsContext on BuildContext {
  /// Адаптивные цвета в зависимости от темы системы
  bool get isDarkMode => MediaQuery.of(this).platformBrightness == Brightness.dark;

  Color get iosBackground => isDarkMode ? AppColors.iosDarkBackground : AppColors.iosLightBackground;
  Color get iosSecondaryBackground => isDarkMode ? AppColors.iosDarkSecondaryBackground : AppColors.iosLightSecondaryBackground;
  Color get iosTertiaryBackground => isDarkMode ? AppColors.iosDarkTertiaryBackground : AppColors.iosLightTertiaryBackground;
  Color get iosSeparator => isDarkMode ? AppColors.iosDarkSeparator : AppColors.iosLightSeparator;
  Color get iosLabel => isDarkMode ? AppColors.iosDarkLabel : AppColors.iosLightLabel;
  Color get iosSecondaryLabel => isDarkMode ? AppColors.iosDarkSecondaryLabel : AppColors.iosLightSecondaryLabel;
  Color get iosTertiaryLabel => isDarkMode ? AppColors.iosDarkTertiaryLabel : AppColors.iosLightTertiaryLabel;
}


