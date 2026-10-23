import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:haven_mobile/core/theme/app_colors.dart';
import 'package:haven_mobile/core/constants/route_constants.dart';
import '../widgets/haven_logo.dart';

/// Animated splash screen for Haven Smart Home.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startNavigationTimer();
  }

  void _startNavigationTimer() {
    _timer = Timer(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _handleNavigation();
    });
  }

  Future<void> _handleNavigation() async {
    // Open directly to the ESP32 Relay dashboard!
    if (!mounted) return;
    context.go(RouteConstants.dashboardPath);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient background glow circles
          Positioned(
            top: -size.width * 0.3,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          )
              .animate()
              .scale(
                duration: 2500.ms,
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.1, 1.1),
                curve: Curves.easeInOut,
              ),

          Positioned(
            bottom: -size.width * 0.2,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.surfaceNavy.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Central Logo and Branding
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HavenLogo(
                  size: 96,
                  showText: false,
                )
                    .animate()
                    .fadeIn(duration: 900.ms, curve: Curves.easeOut)
                    .scale(
                      duration: 900.ms,
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1.0, 1.0),
                      curve: Curves.easeOutBack,
                    )
                    .shimmer(
                      delay: 1000.ms,
                      duration: 1200.ms,
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),

                const SizedBox(height: 28),

                Text(
                  'HAVEN',
                  style: GoogleFonts.inter(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6.0,
                    color: AppColors.textPrimary,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 800.ms)
                    .slideY(
                      begin: 0.3,
                      end: 0,
                      duration: 800.ms,
                      curve: Curves.easeOutQuad,
                    ),

                const SizedBox(height: 8),

                Text(
                  'Smart Home Automation',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.5,
                    color: AppColors.textSecondary,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 650.ms, duration: 800.ms)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      duration: 800.ms,
                      curve: Curves.easeOutQuad,
                    ),
              ],
            ),
          ),

          // Bottom Loading Indicator
          Positioned(
            left: 0,
            right: 0,
            bottom: 50,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accent.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 1100.ms, duration: 500.ms),
          ),
        ],
      ),
    );
  }
}
