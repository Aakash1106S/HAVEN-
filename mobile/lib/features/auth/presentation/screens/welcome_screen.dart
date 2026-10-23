import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haven_mobile/core/constants/route_constants.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100,
            child: _GlowCircle(color: const Color(0xFF00B4A0), size: 320)),
          Positioned(bottom: 80, left: -120,
            child: _GlowCircle(color: const Color(0xFF0F3460), size: 300)),
          SafeArea(
            child: FadeTransition(opacity: _fade,
              child: SlideTransition(position: _slide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      _HavenLogo(),
                      const SizedBox(height: 28),
                      const Text('Haven',
                          style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800,
                              color: Colors.white, letterSpacing: -1.2)),
                      const SizedBox(height: 10),
                      const Text('Control your world',
                          style: TextStyle(fontSize: 17, color: Color(0xFF8892A4))),
                      const SizedBox(height: 52),
                      _FeatureRow(Icons.toggle_on_rounded, 'Smart Control',
                          'Control any appliance from anywhere'),
                      const SizedBox(height: 14),
                      _FeatureRow(Icons.schedule_rounded, 'Automation',
                          'Schedules with full timezone support'),
                      const SizedBox(height: 14),
                      _FeatureRow(Icons.mic_rounded, 'Voice Commands',
                          'Control your home with your voice'),
                      const Spacer(flex: 3),
                      _PrimaryBtn('Get Started',
                          () => context.push(RouteConstants.registerPath)),
                      const SizedBox(height: 12),
                      _OutlineBtn('Sign In',
                          () => context.push(RouteConstants.loginPath)),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.size});
  final Color color; final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
              colors: [color.withOpacity(0.15), Colors.transparent]),
        ),
      );
}

class _HavenLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF00B4A0), Color(0xFF0F3460)]),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: const Color(0xFF00B4A0).withOpacity(0.35),
              blurRadius: 28, offset: const Offset(0, 8))],
        ),
        child: const Icon(Icons.home_rounded, color: Colors.white, size: 46),
      );
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(this.icon, this.title, this.subtitle);
  final IconData icon; final String title, subtitle;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF00B4A0).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF00B4A0), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: const TextStyle(
                    color: Color(0xFF8892A4), fontSize: 12)),
              ],
            ),
          ),
        ],
      );
}

Widget _PrimaryBtn(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity, height: 52,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00B4A0), foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ));

Widget _OutlineBtn(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity, height: 52,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF2A3A5A), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    ));
