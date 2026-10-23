import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/haven_button.dart';

/// Model representing a single page in the onboarding carousel
class _OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;

  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
  });
}

/// 3-page Onboarding Flow:
/// 1. Smart Control - control all appliances from your phone
/// 2. Schedule Everything - set timers and automations
/// 3. Always Connected - physical switches always work
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _pages = const [
    _OnboardingItem(
      title: 'Smart Control',
      description:
          'Control all appliances directly from your phone. Experience instantaneous responsiveness and real-time status across your home.',
      icon: Icons.tune_rounded,
      gradientColors: [AppColors.primary, Color(0xFF0F3460)],
    ),
    _OnboardingItem(
      title: 'Schedule Everything',
      description:
          'Set custom timers and smart automations. Wake up to warm lighting, automated morning routines, and effortless energy savings.',
      icon: Icons.schedule_rounded,
      gradientColors: [Color(0xFF26E5D0), Color(0xFF0D7377)],
    ),
    _OnboardingItem(
      title: 'Always Connected',
      description:
          'Physical switches always work, even without active internet. Dual local offline-sync ensures uninterrupted sanctuary living.',
      icon: Icons.wifi_tethering_rounded,
      gradientColors: [Color(0xFF00B4A0), Color(0xFF162A4E)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              AppColors.surfaceNavy,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Header with Skip Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      )
                    else
                      const SizedBox(width: 48),

                    // Skip action
                    if (!isLastPage)
                      HavenTextButton(
                        label: 'Skip',
                        fontSize: 14,
                        textColor: AppColors.textSecondary,
                        onPressed: _finishOnboarding,
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),

              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final item = _pages[index];
                    return _buildPageContent(item, index == _currentPage);
                  },
                ),
              ),

              // Dots indicator and Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (index) {
                        final isSelected = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isSelected ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceNavyLight,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.45),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 32),

                    // Next / Get Started Primary Button
                    HavenPrimaryButton(
                      label: isLastPage ? 'Get Started' : 'Next',
                      icon: Icon(
                        isLastPage
                            ? Icons.check_circle_outline_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: _nextPage,
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(_OnboardingItem item, bool isActive) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustration container with icon and glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulse ring
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.08),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(0.92, 0.92),
                          end: const Offset(1.08, 1.08),
                          duration: 2600.ms,
                          curve: Curves.easeInOut,
                        ),

                    // Mid glowing container
                    Container(
                      width: 156,
                      height: 156,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            item.gradientColors.first.withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // Inner badge
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: item.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: item.gradientColors.first.withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        item.icon,
                        size: 54,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
                    .animate(target: isActive ? 1 : 0)
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.easeOutBack),

                const SizedBox(height: 48),

                // Title
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: AppColors.textPrimary,
                  ),
                )
                    .animate(target: isActive ? 1 : 0)
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 16),

                // Description
                Text(
                  item.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                )
                    .animate(target: isActive ? 1 : 0)
                    .fadeIn(delay: 350.ms, duration: 400.ms)
                    .slideY(begin: 0.15, end: 0),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
