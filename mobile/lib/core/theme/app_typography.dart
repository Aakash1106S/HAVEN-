import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography configuration using Google Fonts Inter for Haven Smart Home.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';

  /// Builds a complete [TextTheme] based on Google Fonts Inter with defined sizes and weights.
  static TextTheme createTextTheme([Color? defaultColor]) {
    return TextTheme(
      // displayLarge: 32sp, bold
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: defaultColor,
      ),
      // displayMedium: 28sp, bold
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: defaultColor,
      ),
      // displaySmall: 24sp, semibold
      displaySmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: defaultColor,
      ),
      // headlineLarge: 22sp, semibold
      headlineLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: defaultColor,
      ),
      // headlineMedium: 20sp, semibold
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: defaultColor,
      ),
      // headlineSmall: 18sp, semibold
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        color: defaultColor,
      ),
      // titleLarge: 16sp, semibold
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: defaultColor,
      ),
      // titleMedium: 14sp, medium
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: defaultColor,
      ),
      // titleSmall: 12sp, medium
      titleSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: defaultColor,
      ),
      // bodyLarge: 16sp, regular
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: defaultColor,
      ),
      // bodyMedium: 14sp, regular
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: defaultColor,
      ),
      // bodySmall: 12sp, regular
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: defaultColor,
      ),
      // labelLarge: 14sp, medium
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: defaultColor,
      ),
      // labelMedium: 12sp, medium
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: defaultColor,
      ),
      // labelSmall: 11sp, medium
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: defaultColor,
      ),
    );
  }

  /// Default text theme with neutral color.
  static final TextTheme textTheme = createTextTheme();

  /// Dark theme text styling using [AppColors.onSurface].
  static final TextTheme darkTextTheme = createTextTheme(AppColors.onSurface);

  /// Light theme text styling using [AppColors.textPrimaryLight].
  static final TextTheme lightTextTheme = createTextTheme(AppColors.textPrimaryLight);
}
