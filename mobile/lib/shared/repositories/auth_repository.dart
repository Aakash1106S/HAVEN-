import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

/// Custom exception class wrapping Firebase authentication errors
/// with human-readable, user-friendly messages.
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  factory AuthException.fromFirebaseException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No account found with this email address.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please verify and try again.';
        break;
      case 'invalid-credential':
        message = 'Invalid email or password. Please try again.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email address.';
        break;
      case 'invalid-email':
        message = 'Please provide a valid email address.';
        break;
      case 'weak-password':
        message = 'The password is too weak. Please use at least 6 characters.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled. Please contact support.';
        break;
      case 'operation-not-allowed':
        message = 'This sign-in method is currently disabled.';
        break;
      case 'too-many-requests':
        message = 'Too many failed attempts. Please wait a moment and try again.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your internet connection.';
        break;
      case 'requires-recent-login':
        message = 'This operation requires recent authentication. Please sign in again.';
        break;
      case 'expired-action-code':
        message = 'The action link has expired. Please request a new one.';
        break;
      case 'invalid-action-code':
        message = 'The action code is invalid. Please request a new one.';
        break;
      case 'user-token-expired':
        message = 'Your session has expired. Please sign in again.';
        break;
      default:
        message = e.message ?? 'An unexpected authentication error occurred.';
    }
    return AuthException(message, code: e.code);
  }

  @override
  String toString() => message;
}

/// Repository responsible for user authentication and user profile management in Firestore.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  /// Collection reference to 'users'
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently authenticated Firebase user, or null if unauthenticated
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        await _saveUserProfile(user);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to sign in: ${e.toString()}');
    }
  }

  /// Register a new user with email, password, and display name
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        final trimmedName = displayName.trim();
        await user.updateDisplayName(trimmedName);
        await user.reload();
        final refreshedUser = _auth.currentUser ?? user;
        await _saveUserProfile(refreshedUser, displayName: trimmedName);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to register: ${e.toString()}');
    }
  }

  /// Send email verification link to current user
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('No user is currently signed in.');
    }

    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseException(e);
    } catch (e) {
      throw AuthException('Failed to send verification email: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseException(e);
    } catch (e) {
      throw AuthException('Failed to send password reset email: ${e.toString()}');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseException(e);
    } catch (e) {
      throw AuthException('Failed to sign out: ${e.toString()}');
    }
  }

  /// Delete current user account and user document in Firestore
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('No user is currently signed in.');
    }

    final uid = user.uid;

    try {
      // 1. Delete Firestore user document
      await _usersCollection.doc(uid).delete();

      // 2. Delete Firebase Auth user
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseException(e);
    } catch (e) {
      throw AuthException('Failed to delete account: ${e.toString()}');
    }
  }

  /// Update display name for current user
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('No user is currently signed in.');
    }

    final trimmedName = name.trim();

    try {
      await user.updateDisplayName(trimmedName);
      await user.reload();
      final updatedUser = _auth.currentUser ?? user;
      await _saveUserProfile(updatedUser, displayName: trimmedName);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseException(e);
    } catch (e) {
      throw AuthException('Failed to update display name: ${e.toString()}');
    }
  }

  /// Save or update user profile in Firestore at users/{uid}
  /// Writes uid, email, displayName, createdAt (only on create), and updatedAt
  Future<void> _saveUserProfile(User user, {String? displayName}) async {
    try {
      final docRef = _usersCollection.doc(user.uid);
      final doc = await docRef.get();
      final name = displayName ?? user.displayName;

      if (!doc.exists) {
        await docRef.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'displayName': name,
          'photoUrl': user.photoURL,
          'emailVerified': user.emailVerified,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final updates = <String, dynamic>{
          'email': user.email ?? '',
          'emailVerified': user.emailVerified,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (name != null) {
          updates['displayName'] = name;
        }
        if (user.photoURL != null) {
          updates['photoUrl'] = user.photoURL;
        }

        await docRef.update(updates);
      }
    } catch (e) {
      // Firestore profile sync failure shouldn't silently swallow if critical,
      // but rethrow as AuthException so caller is informed
      throw AuthException('Failed to persist user profile: ${e.toString()}');
    }
  }

  /// Reload current user profile from Firebase to refresh email verification status
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Whether the current authenticated user has verified their email address
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Get user profile from Firestore by UID
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserProfile.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }
}
