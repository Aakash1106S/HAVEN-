import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Haven logo widget:
/// Stylized 'H' and house motif in a gradient container with rounded corners and drop shadow.
class HavenLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String? subtitle;
  final String? heroTag;

  const HavenLogo({
    super.key,
    this.size = 80.0,
    this.showText = false,
    this.subtitle,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    Widget logoBadge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            Color(0xFF0D7377),
            AppColors.surfaceNavy,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.38),
            blurRadius: size * 0.35,
            spreadRadius: 1,
            offset: Offset(0, size * 0.12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.08),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.58, size * 0.58),
          painter: _HavenLogoMarkPainter(),
        ),
      ),
    );

    if (heroTag != null) {
      logoBadge = Hero(tag: heroTag!, child: logoBadge);
    }

    if (!showText) {
      return logoBadge;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoBadge,
        const SizedBox(height: 16),
        Text(
          'HAVEN',
          style: GoogleFonts.inter(
            fontSize: (size * 0.32).clamp(18.0, 32.0),
            fontWeight: FontWeight.w800,
            letterSpacing: 4.0,
            color: AppColors.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: GoogleFonts.inter(
              fontSize: (size * 0.15).clamp(11.0, 15.0),
              fontWeight: FontWeight.w400,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom painter for the Haven 'H' + House icon mark
class _HavenLogoMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Roof peak above crossbar: forms a house gable + 'H' top
    final roofPath = Path()
      ..moveTo(w * 0.18, h * 0.42)
      ..lineTo(w * 0.5, h * 0.12)
      ..lineTo(w * 0.82, h * 0.42);

    canvas.drawPath(roofPath, paint);

    // Left vertical pillar of 'H'
    canvas.drawLine(
      Offset(w * 0.24, h * 0.32),
      Offset(w * 0.24, h * 0.88),
      paint,
    );

    // Right vertical pillar of 'H'
    canvas.drawLine(
      Offset(w * 0.76, h * 0.32),
      Offset(w * 0.76, h * 0.88),
      paint,
    );

    // Horizontal crossbar of 'H'
    canvas.drawLine(
      Offset(w * 0.24, h * 0.58),
      Offset(w * 0.76, h * 0.58),
      paint,
    );

    // Ambient glow dot in center / smart home beacon
    final dotPaint = Paint()
      ..color = const Color(0xFF14FFEC)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.58), size.width * 0.08, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
