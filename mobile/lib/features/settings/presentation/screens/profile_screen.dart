import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haven_mobile/core/theme/app_colors.dart';
import 'package:haven_mobile/core/constants/route_constants.dart';
import 'package:haven_mobile/core/di/providers.dart';
import 'package:haven_mobile/core/di/repository_providers.dart';
import 'package:haven_mobile/features/auth/providers/auth_providers.dart';
import 'package:haven_mobile/core/utils/snackbar_utils.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(authRepositoryProvider).updateDisplayName(name);
      if (mounted) showSuccessSnackBar(context, 'Display name updated');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Failed to update name: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _resetPassword(String email) async {
    try {
      await ref.read(authNotifierProvider.notifier).sendPasswordReset(email);
      if (mounted) {
        showSuccessSnackBar(context, 'Password reset email sent to $email');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Failed: $e');
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Delete Account Forever?',
            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
        content: const Text(
          'This will permanently delete your user profile and remove your access. This action cannot be undone.',
          style: TextStyle(color: AppColors.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(authNotifierProvider.notifier).deleteAccount();
      if (mounted && success) {
        context.go(RouteConstants.welcomePath);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;

    if (!_initialized && user != null) {
      _nameCtrl.text = user.displayName ?? '';
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Display Name',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.cardDark,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveName,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save'),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text('Email Address',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, color: AppColors.mutedText, size: 20),
                  const SizedBox(width: 12),
                  Text(user?.email ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const Spacer(),
                  if (user?.emailVerified == true)
                    const Icon(Icons.verified_rounded, color: AppColors.online, size: 18),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text('Security',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                if (user?.email != null) _resetPassword(user!.email!);
              },
              icon: const Icon(Icons.lock_reset_rounded, size: 18),
              label: const Text('Send Password Reset Email'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppColors.borderDark),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 48),
            const Divider(color: AppColors.borderDark),
            const SizedBox(height: 16),
            const Text('Danger Zone',
                style: TextStyle(
                    color: AppColors.error, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _deleteAccount,
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: const Text('Delete Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error.withValues(alpha: 0.15),
                foregroundColor: AppColors.error,
                elevation: 0,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
