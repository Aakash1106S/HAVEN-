import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the singleton [FirebaseAuth] instance.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provides the singleton [FirebaseFirestore] instance.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Streams the currently authenticated Firebase [User] or null if signed out.
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

/// Derives the current authenticated user's ID or null.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.uid;
});

/// Provides the singleton [FirebaseMessaging] instance.
final messagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

/// Streams the primary active network [ConnectivityResult] using connectivity_plus.
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    if (results.isEmpty) return ConnectivityResult.none;
    return results.firstWhere(
      (result) => result != ConnectivityResult.none,
      orElse: () => ConnectivityResult.none,
    );
  });
});

/// Derives a boolean indicating whether the device is currently online.
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);
  return connectivityAsync.when(
    data: (result) => result != ConnectivityResult.none,
    loading: () => true,
    error: (_, __) => false,
  );
});

/// Tracks whether the active user has at least one configured home.
final userHasHomeProvider = StateProvider<bool>((ref) => false);

/// Tracks the currently active home identifier.
final currentHomeIdProvider = StateProvider<String?>((ref) => null);
