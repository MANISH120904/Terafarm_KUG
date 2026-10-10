import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter/foundation.dart';

import '../core/app_config.dart';
import '../demo/demo_seed.dart';
import '../firebase_options.dart';
import 'ai_service.dart';
import 'cart_service.dart';
import 'media_service.dart';

/// Central locator for auth, firestore, storage, media, AI, and cart.
class AppServices {
  AppServices._();

  static late FirebaseAuth auth;
  static late FirebaseFirestore firestore;
  static late FirebaseStorage storage;
  static late MediaService media;
  static late AiService ai;
  static late CartService cart;

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static String? initError;

  static Future<void> init() async {
    if (_initialized) return;

    cart = CartService();
    ai = AppConfig.hasGeminiKey || AppConfig.hasOpenWeatherKey
        ? LiveOrDemoAiService()
        : DemoAiService();

    if (AppConfig.demoMode) {
      await _initDemo();
    } else {
      await _initFirebase();
    }

    media = MediaService(storage);
    _initialized = true;
  }

  static Future<void> _initDemo() async {
    final mockAuth = MockFirebaseAuth(
      mockUser: DemoSeed.demoMockUser,
      signedIn: false,
    );
    final fakeFs = FakeFirebaseFirestore();
    final mockStorage = MockFirebaseStorage();

    await DemoSeed.seed(fakeFs);

    auth = mockAuth;
    firestore = fakeFs;
    storage = mockStorage;
    initError = null;
    debugPrint('AppServices: demo mode active (in-memory Firebase fakes).');
  }

  static Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      auth = FirebaseAuth.instance;
      firestore = FirebaseFirestore.instance;
      storage = FirebaseStorage.instance;
      initError = null;
    } catch (e, st) {
      initError = e.toString();
      debugPrint('Firebase init failed: $e\n$st');
      // Fall back to demo so the app remains demonstrable.
      await _initDemo();
      initError =
          'Firebase unavailable ($e). Running in local demo mode instead.\n'
          'Use --dart-define-from-file=config/demo.json for an explicit demo build.';
    }
  }

  /// One-tap demo login used by the DEV login button.
  static Future<UserCredential> signInAsDemoUser() async {
    if (AppConfig.demoMode || auth is MockFirebaseAuth) {
      return auth.signInWithEmailAndPassword(
        email: DemoSeed.demoEmail,
        password: DemoSeed.demoPassword,
      );
    }
    // Should not be reachable in production builds without demo flag.
    throw StateError('Demo login is only available when DEMO_MODE is enabled.');
  }

  static Future<void> signOut() async {
    cart.clear();
    await auth.signOut();
  }
}
