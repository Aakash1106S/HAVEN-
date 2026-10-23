import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haven_mobile/core/di/providers.dart';
import '../widgets/haven_auth_widgets.dart';
import '../../providers/auth_providers.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/di/repository_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(authNotifierProvider.notifier);
    final success = await notifier.signIn(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;

    if (success) {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null && !user.emailVerified) {
        context.go(RouteConstants.emailVerificationPath);
        return;
      }
      final homes = await ref
          .read(homeRepositoryProvider)
          .getUserHomes(user?.uid ?? '')
          .first;
      if (!mounted) return;
      if (homes.isEmpty) {
        context.go(RouteConstants.homeSetupPath);
      } else {
        context.go(RouteConstants.dashboardPath);
      }
    } else {
      final error = ref.read(authNotifierProvider).error;
      if (error != null) showErrorSnackBar(context, error);
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
        title: const Text('Sign In',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text('Welcome back',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 6),
                const Text('Sign in to control your home',
                    style: TextStyle(color: Color(0xFF8892A4), fontSize: 15)),
                const SizedBox(height: 36),

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
                const SizedBox(height: 16),

                HavenTextField(
                  controller: _passCtrl,
                  labelText: 'Password',
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signIn(),
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: Color(0xFF8892A4), size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: const Color(0xFF8892A4), size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Password is required' : null,
                  autofillHints: const [AutofillHints.password],
                ),
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        context.push(RouteConstants.forgotPasswordPath),
                    child: const Text('Forgot password?',
                        style: TextStyle(color: Color(0xFF00B4A0), fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 24),

                HavenPrimaryButton(
                  label: 'Sign In',
                  isLoading: authState.isLoading,
                  onPressed: _signIn,
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?",
                        style: TextStyle(color: Color(0xFF8892A4), fontSize: 14)),
                    TextButton(
                      onPressed: () =>
                          context.pushReplacement(RouteConstants.registerPath),
                      child: const Text('Register',
                          style: TextStyle(
                              color: Color(0xFF00B4A0),
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
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
