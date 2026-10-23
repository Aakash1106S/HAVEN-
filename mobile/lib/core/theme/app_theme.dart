import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Complete application theme definitions (Dark & Light) for Haven Smart Home.
class AppTheme {
  AppTheme._();

  /// Primary theme: Dark Theme (Material 3)
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
      primary: AppColors.accent,
      onPrimary: AppColors.primary,
      primaryContainer: AppColors.card,
      onPrimaryContainer: AppColors.onSurface,
      secondary: AppColors.secondaryAccent,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      error: AppColors.error,
      onError: Colors.white,
    );

    final textTheme = AppTypography.darkTextTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.primary,
      textTheme: textTheme,

      // AppBar theme: transparent background, no elevation, white icons
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card theme: rounded corners 16dp, card color
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      // ElevatedButton theme: filled style, rounded 12dp
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // InputDecoration theme: filled, rounded 12dp
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.mutedText,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurface,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),

      // SnackBar theme: bottom, rounded
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: AppColors.surface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurface,
        ),
      ),

      // NavigationBar theme: transparent, accent selected
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.accent.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.accent);
          }
          return const IconThemeData(color: AppColors.mutedText);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: AppColors.mutedText,
          );
        }),
      ),

      // BottomSheet theme: rounded top 24dp
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Chip theme: rounded
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // Dialog theme: rounded 20dp
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: AppColors.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurface,
        ),
      ),

      dividerColor: AppColors.borderDark,
    );
  }

  /// Light Theme (Material 3)
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: const Color(0xFFE0E3EB),
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.secondaryAccent,
      onSecondary: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      error: AppColors.error,
      onError: Colors.white,
    );

    final textTheme = AppTypography.lightTextTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: textTheme,

      // AppBar theme: transparent background, no elevation
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.primary),
        actionsIconTheme: const IconThemeData(color: AppColors.primary),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card theme: rounded corners 16dp
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      // ElevatedButton theme: filled style, rounded 12dp
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // InputDecoration theme: filled, rounded 12dp
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),

      // SnackBar theme: bottom, rounded
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: AppColors.primary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
      ),

      // NavigationBar theme: transparent, accent selected
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.accent.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.accent);
          }
          return const IconThemeData(color: AppColors.textSecondaryLight);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondaryLight,
          );
        }),
      ),

      // BottomSheet theme: rounded top 24dp
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        modalBackgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Chip theme: rounded
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        selectedColor: AppColors.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // Dialog theme: rounded 20dp
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimaryLight,
        ),
      ),

      dividerColor: AppColors.borderLight,
    );
  }
}
