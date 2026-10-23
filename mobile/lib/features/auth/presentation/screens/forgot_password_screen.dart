import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/haven_auth_widgets.dart';
import '../../providers/auth_providers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/snackbar_utils.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authNotifierProvider.notifier)
        .sendPasswordReset(_emailCtrl.text.trim());
    if (!mounted) return;
    if (success) {
      setState(() => _sent = true);
    } else {
      final err = ref.read(authNotifierProvider).error;
      if (err != null) showErrorSnackBar(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Forgot Password',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent ? _SuccessView(email: _emailCtrl.text) : Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Icon(Icons.lock_reset_rounded,
                    size: 56, color: Color(0xFF00B4A0)),
                const SizedBox(height: 24),
                const Text('Reset your password',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 10),
                const Text(
                    'Enter your email address and we\'ll send you a link to reset your password.',
                    style: TextStyle(color: Color(0xFF8892A4), fontSize: 14, height: 1.5)),
                const SizedBox(height: 36),
                HavenTextField(
                  controller: _emailCtrl,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _send(),
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: Color(0xFF8892A4), size: 20),
                  validator: Validators.email,
                ),
                const SizedBox(height: 28),
                HavenPrimaryButton(
                  label: 'Send Reset Link',
                  isLoading: authState.isLoading,
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const SizedBox(height: 48),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF00B4A0).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_rounded,
                size: 40, color: Color(0xFF00B4A0)),
          ),
          const SizedBox(height: 24),
          const Text('Email sent!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Text('We\'ve sent a reset link to\n$email',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8892A4), fontSize: 14, height: 1.6)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00B4A0),
                side: const BorderSide(color: Color(0xFF00B4A0), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back to Sign In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
}
