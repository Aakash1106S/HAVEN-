import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/haven_auth_widgets.dart';
import '../../providers/auth_providers.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/snackbar_utils.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  int get _passwordStrength {
    final p = _passCtrl.text;
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8) score++;
    if (p.contains(RegExp(r'[A-Z]'))) score++;
    if (p.contains(RegExp(r'[0-9]'))) score++;
    if (p.contains(RegExp(r'[!@#\$%^&*]'))) score++;
    return score;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      showWarningSnackBar(context, 'Please accept the terms of service');
      return;
    }
    final success = await ref.read(authNotifierProvider.notifier).register(
          _emailCtrl.text.trim(),
          _passCtrl.text,
          _nameCtrl.text.trim(),
        );
    if (!mounted) return;
    if (success) {
      context.go(RouteConstants.emailVerificationPath);
    } else {
      final err = ref.read(authNotifierProvider).error;
      if (err != null) showErrorSnackBar(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final strength = _passwordStrength;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Create Account',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Join Haven',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 6),
                const Text('Create your account to get started',
                    style: TextStyle(color: Color(0xFF8892A4), fontSize: 15)),
                const SizedBox(height: 32),

                HavenTextField(
                  controller: _nameCtrl,
                  labelText: 'Full Name',
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.person_outline,
                      color: Color(0xFF8892A4), size: 20),
                  validator: Validators.name,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: 14),

                HavenTextField(
                  controller: _emailCtrl,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: Color(0xFF8892A4), size: 20),
                  validator: Validators.email,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 14),

                HavenTextField(
                  controller: _passCtrl,
                  labelText: 'Password',
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: Color(0xFF8892A4), size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: const Color(0xFF8892A4), size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  validator: Validators.password,
                  onFieldSubmitted: (_) => setState(() {}),
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: 8),

                // Password strength indicator
                if (_passCtrl.text.isNotEmpty) ...[
                  Row(
                    children: List.generate(4, (i) => Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: i < strength
                              ? [Colors.red, Colors.orange,
                                 Colors.yellow, const Color(0xFF00B4A0)][strength - 1]
                              : const Color(0xFF2A3A5A),
                        ),
                      ),
                    )),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ['', 'Weak', 'Fair', 'Good', 'Strong'][strength],
                    style: TextStyle(fontSize: 11,
                        color: strength < 2 ? Colors.red :
                               strength < 3 ? Colors.orange :
                               strength < 4 ? Colors.yellow :
                               const Color(0xFF00B4A0)),
                  ),
                ],
                const SizedBox(height: 14),

                HavenTextField(
                  controller: _confirmCtrl,
                  labelText: 'Confirm Password',
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: Color(0xFF8892A4), size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: const Color(0xFF8892A4), size: 20,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) =>
                      Validators.confirmPassword(v, _passCtrl.text),
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: 20),

                // Terms checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (v) =>
                          setState(() => _agreedToTerms = v ?? false),
                      activeColor: const Color(0xFF00B4A0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(
                              color: Color(0xFF8892A4), fontSize: 13),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(
                                  color: Color(0xFF00B4A0),
                                  fontWeight: FontWeight.w500),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                  color: Color(0xFF00B4A0),
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                HavenPrimaryButton(
                  label: 'Create Account',
                  isLoading: authState.isLoading,
                  onPressed: _register,
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?',
                        style: TextStyle(color: Color(0xFF8892A4), fontSize: 14)),
                    TextButton(
                      onPressed: () =>
                          context.pushReplacement(RouteConstants.loginPath),
                      child: const Text('Sign In',
                          style: TextStyle(color: Color(0xFF00B4A0),
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
