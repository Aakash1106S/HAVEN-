import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Primary filled emerald green button with full-width support, loading state,
/// and smooth pressed feedback.
class HavenPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon;
  final double height;
  final double? width;
  final Color? backgroundColor;
  final Color? textColor;

  const HavenPrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.height = 54.0,
    this.width,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDisabled = isDisabled || isLoading || onPressed == null;
    final themeBg = backgroundColor ?? AppColors.primary;
    final themeFg = textColor ?? Colors.white;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: effectiveDisabled ? 0.6 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: effectiveDisabled
                ? []
                : [
                    BoxShadow(
                      color: (backgroundColor ?? AppColors.primary).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: effectiveDisabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeBg,
              foregroundColor: themeFg,
              disabledBackgroundColor: themeBg.withValues(alpha: 0.6),
              disabledForegroundColor: themeFg.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(themeFg),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        icon!,
                        const SizedBox(width: 10),
                      ],
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: themeFg,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Outlined button with emerald accent border and subtle dark background.
class HavenSecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon;
  final double height;
  final double? width;
  final Color? borderColor;
  final Color? textColor;

  const HavenSecondaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.height = 54.0,
    this.width,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDisabled = isDisabled || isLoading || onPressed == null;
    final color = borderColor ?? AppColors.primary;
    final text = textColor ?? AppColors.textPrimary;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: effectiveDisabled ? 0.6 : 1.0,
        child: OutlinedButton(
          onPressed: effectiveDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: text,
            backgroundColor: AppColors.surfaceNavy.withValues(alpha: 0.25),
            side: BorderSide(
              color: effectiveDisabled ? color.withValues(alpha: 0.3) : color,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: text,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Minimal text button with optional underline or accent styling
class HavenTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon;
  final Color? textColor;
  final double fontSize;
  final FontWeight fontWeight;

  const HavenTextButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.textColor,
    this.fontSize = 14.0,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDisabled = isDisabled || isLoading || onPressed == null;
    final color = textColor ?? AppColors.primary;

    return TextButton(
      onPressed: effectiveDisabled ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: color.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  icon!,
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    color: effectiveDisabled ? color.withValues(alpha: 0.4) : color,
                  ),
                ),
              ],
            ),
    );
  }
}
