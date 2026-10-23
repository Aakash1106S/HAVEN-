import 'package:flutter/material.dart';

/// Premium Haven color palette and color scheme configurations.
class AppColors {
  AppColors._();

  // Premium Haven Brand Colors
  static const Color primary = Color(0xFF1A1B2E);
  static const Color surface = Color(0xFF16213E);
  static const Color card = Color(0xFF0F3460);
  static const Color accent = Color(0xFF00B4A0);
  static const Color secondaryAccent = Color(0xFFE94560);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFE8EDF2);
  static const Color mutedText = Color(0xFF8892A4);

  // Status Colors
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color online = Color(0xFF2ECC71);
  static const Color offline = Color(0xFF95A5A6);
  static const Color pending = Color(0xFFF39C12);

  // Aliases for convenience across UI widgets
  static const Color background = backgroundDark;
  static const Color surfaceNavy = surfaceDark;
  static const Color surfaceNavyLight = cardDark;
  static const Color primaryLight = accent;
  static const Color textPrimary = onSurface;
  static const Color textSecondary = mutedText;
  static const Color textMuted = mutedText;

  // Backgrounds & Surfaces
  static const Color backgroundDark = Color(0xFF121324);
  static const Color surfaceDark = Color(0xFF16213E);
  static const Color cardDark = Color(0xFF0F3460);
  static const Color borderDark = Color(0xFF233554);

  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF1A1B2E);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Dark Color Scheme (Primary)
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: accent,
    onPrimary: primary,
    primaryContainer: card,
    onPrimaryContainer: onSurface,
    secondary: secondaryAccent,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF5C1B2A),
    onSecondaryContainer: Color(0xFFFFD9DF),
    tertiary: accent,
    onTertiary: primary,
    tertiaryContainer: Color(0xFF004D40),
    onTertiaryContainer: Color(0xFFA7F3D0),
    error: error,
    onError: Colors.white,
    errorContainer: Color(0xFF5C1D1D),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: surface,
    onSurface: onSurface,
    surfaceContainerHighest: card,
    onSurfaceVariant: mutedText,
    outline: borderDark,
    outlineVariant: Color(0xFF1B2A4A),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFE8EDF2),
    onInverseSurface: primary,
    inversePrimary: Color(0xFF00796B),
  );

  // Light Color Scheme
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: Color(0xFFE0E3EB),
    onPrimaryContainer: primary,
    secondary: secondaryAccent,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFFFD9DF),
    onSecondaryContainer: Color(0xFF400012),
    tertiary: accent,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFB2DFDB),
    onTertiaryContainer: Color(0xFF00332C),
    error: error,
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: surfaceLight,
    onSurface: textPrimaryLight,
    surfaceContainerHighest: Color(0xFFEEF2F6),
    onSurfaceVariant: textSecondaryLight,
    outline: borderLight,
    outlineVariant: Color(0xFFCBD5E1),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF16213E),
    onInverseSurface: onSurface,
    inversePrimary: accent,
  );
}
