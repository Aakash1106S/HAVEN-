import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haven_mobile/core/di/providers.dart';
import '../../providers/auth_providers.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/di/repository_providers.dart';
import '../../../../core/utils/snackbar_utils.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});
  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  Timer? _checkTimer;
  Timer? _cooldownTimer;
  int _cooldown = 0;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    // Auto-check every 5 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkVerification(silent: true));
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification({bool silent = false}) async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final verified = await ref.read(authNotifierProvider.notifier).checkEmailVerified();
      if (!mounted) return;
      setState(() => _checking = false);
      if (verified) {
        _checkTimer?.cancel();
        _navigateToNextScreen();
      } else if (!silent) {
        showInfoSnackBar(context, 'Email not yet verified. Please click the link in your email or click "Skip for now".');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _checking = false);
    }
  }

  Future<void> _navigateToNextScreen() async {
    try {
      final uid = ref.read(authStateProvider).valueOrNull?.uid ?? '';
      if (uid.isEmpty) {
        context.go(RouteConstants.homeSetupPath);
        return;
      }
      final homes = await ref
          .read(homeRepositoryProvider)
          .getUserHomes(uid)
          .first;
      if (!mounted) return;
      if (homes.isEmpty) {
        context.go(RouteConstants.homeSetupPath);
      } else {
        context.go(RouteConstants.dashboardPath);
      }
    } catch (_) {
      if (!mounted) return;
      // In case Firestore database is still initializing or empty, go to home setup
      context.go(RouteConstants.homeSetupPath);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    final success =
        await ref.read(authNotifierProvider.notifier).sendEmailVerification();
    if (!mounted) return;
    if (success) {
      showSuccessSnackBar(context, 'Verification email sent!');
      setState(() => _cooldown = 60);
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() => _cooldown--);
        if (_cooldown <= 0) t.cancel();
      });
    } else {
      final err = ref.read(authNotifierProvider).error;
      if (err != null) showErrorSnackBar(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authStateProvider).valueOrNull?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF00B4A0).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_unread_rounded,
                    size: 50, color: Color(0xFF00B4A0)),
              ),
              const SizedBox(height: 32),
              const Text('Verify your email',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 14),
              Text(
                'We\'ve sent a verification link to\n$email\n\nTap the link in the email to verify your account.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF8892A4), fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 48),

              // Check status button
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _checking ? null : _checkVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B4A0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _checking
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2,
                              color: Colors.white))
                      : const Text('I\'ve verified my email',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 14),

              // Resend button
              SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton(
                  onPressed: _cooldown > 0 ? null : _resend,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00B4A0),
                    side: const BorderSide(color: Color(0xFF00B4A0), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _cooldown > 0 ? 'Resend in ${_cooldown}s' : 'Resend email',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Dev / Quick bypass
              TextButton.icon(
                onPressed: _navigateToNextScreen,
                icon: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF00B4A0)),
                label: const Text('Skip for now (Continue to Setup)',
                    style: TextStyle(color: Color(0xFF00B4A0), fontSize: 14, fontWeight: FontWeight.w500)),
              ),

              const Spacer(),

              TextButton(
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).signOut(),
                child: const Text('Sign out',
                    style: TextStyle(color: Color(0xFF8892A4), fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
