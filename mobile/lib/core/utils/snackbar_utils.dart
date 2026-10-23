import 'package:flutter/material.dart';

/// Utility functions for showing SnackBars in Haven.
void showSuccessSnackBar(BuildContext context, String message) {
  _showSnackBar(context, message, const Color(0xFF27AE60), Icons.check_circle_outline);
}

void showErrorSnackBar(BuildContext context, String message) {
  _showSnackBar(context, message, const Color(0xFFE74C3C), Icons.error_outline);
}

void showInfoSnackBar(BuildContext context, String message) {
  _showSnackBar(context, message, const Color(0xFF00B4A0), Icons.info_outline);
}

void showWarningSnackBar(BuildContext context, String message) {
  _showSnackBar(context, message, const Color(0xFFF39C12), Icons.warning_amber_outlined);
}

void _showSnackBar(BuildContext context, String message, Color color, IconData icon) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
}
