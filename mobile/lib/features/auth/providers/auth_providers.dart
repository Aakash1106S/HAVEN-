import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/repository_providers.dart';

/// Auth notifier state — tracks in-progress async operation and optional error.
class AuthState {
  final bool isLoading;
  final String? error;
  final bool success;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  AuthState copyWith({bool? isLoading, String? error, bool? success}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState());

  final Ref _ref;

  Future<bool> signIn(String email, String password) async {
    state = const AuthState(isLoading: true);
    try {
      await _ref.read(authRepositoryProvider).signInWithEmailAndPassword(email, password);
      state = const AuthState(success: true);
      return true;
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  Future<bool> register(String email, String password, String displayName) async {
    state = const AuthState(isLoading: true);
    try {
      await _ref.read(authRepositoryProvider).registerWithEmailAndPassword(email, password, displayName);
      state = const AuthState(success: true);
      return true;
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await _ref.read(authRepositoryProvider).signOut();
    state = const AuthState();
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AuthState(isLoading: true);
    try {
      await _ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      state = const AuthState(success: true);
      return true;
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  Future<bool> sendEmailVerification() async {
    state = const AuthState(isLoading: true);
    try {
      await _ref.read(authRepositoryProvider).sendEmailVerification();
      state = const AuthState(success: true);
      return true;
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  Future<bool> checkEmailVerified() async {
    await _ref.read(authRepositoryProvider).reloadUser();
    return _ref.read(authRepositoryProvider).isEmailVerified;
  }

  Future<bool> deleteAccount() async {
    state = const AuthState(isLoading: true);
    try {
      await _ref.read(authRepositoryProvider).deleteAccount();
      state = const AuthState(success: true);
      return true;
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  void clearError() => state = const AuthState();
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
