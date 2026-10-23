import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

/// Firebase configuration options for Web & Desktop.
const FirebaseOptions kDefaultFirebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyCtnbcbAy1xctlp-xni1zV9Bl3T6-poVPk",
  authDomain: "haven-a255c.firebaseapp.com",
  projectId: "haven-a255c",
  storageBucket: "haven-a255c.firebasestorage.app",
  messagingSenderId: "950323698683",
  appId: "1:950323698683:web:2111ad6943628afaeb495e",
);

const FirebaseOptions kAndroidFirebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyCtnbcbAy1xctlp-xni1zV9Bl3T6-poVPk",
  appId: "1:950323698683:android:2111ad6943628afaeb495e",
  messagingSenderId: "950323698683",
  projectId: "haven-a255c",
  storageBucket: "haven-a255c.firebasestorage.app",
);

/// Initializes Firebase and all related services across Web, Android, iOS, and Desktop.
Future<void> initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) {
    debugPrint('Firebase already initialized: ${Firebase.apps.first.name}');
    return;
  }

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(options: kDefaultFirebaseOptions);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await Firebase.initializeApp();
      } catch (e) {
        debugPrint('Native Firebase.initializeApp() returned: $e. Falling back to explicit Android options.');
        await Firebase.initializeApp(options: kAndroidFirebaseOptions);
      }
    } else {
      try {
        await Firebase.initializeApp();
      } catch (_) {
        await Firebase.initializeApp(options: kDefaultFirebaseOptions);
      }
    }
    debugPrint('Firebase initialized successfully. Active apps: ${Firebase.apps.length}');
  } catch (e, stack) {
    debugPrint('Firebase initialization note: $e\n$stack');
  }

  // Configure Firestore
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint('Firestore settings note: $e');
  }

  // Activate App Check only on Android & iOS
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
    } catch (e) {
      debugPrint('AppCheck note: $e');
    }
  }
}
