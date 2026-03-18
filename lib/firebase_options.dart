// SciBot Firebase Options
// Firebase configuration loaded from .env file for security.
// Make sure .env file exists with the required Firebase keys.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static String _env(String key) => dotenv.env[key] ?? '';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return web;
      case TargetPlatform.linux:
        return web;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // WEB Configuration
  // ═══════════════════════════════════════════════════════════
  static FirebaseOptions get web => FirebaseOptions(
    apiKey: _env('FIREBASE_WEB_API_KEY'),
    appId: _env('FIREBASE_WEB_APP_ID'),
    messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _env('FIREBASE_PROJECT_ID'),
    authDomain: _env('FIREBASE_WEB_AUTH_DOMAIN'),
    storageBucket: _env('FIREBASE_STORAGE_BUCKET'),
    measurementId: _env('FIREBASE_WEB_MEASUREMENT_ID'),
  );

  // ═══════════════════════════════════════════════════════════
  // ANDROID Configuration
  // ═══════════════════════════════════════════════════════════
  static FirebaseOptions get android => FirebaseOptions(
    apiKey: _env('FIREBASE_ANDROID_API_KEY'),
    appId: _env('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _env('FIREBASE_PROJECT_ID'),
    storageBucket: _env('FIREBASE_STORAGE_BUCKET'),
  );

  // ═══════════════════════════════════════════════════════════
  // iOS Configuration
  // ═══════════════════════════════════════════════════════════
  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: _env('FIREBASE_IOS_API_KEY'),
    appId: _env('FIREBASE_IOS_APP_ID'),
    messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _env('FIREBASE_PROJECT_ID'),
    storageBucket: _env('FIREBASE_STORAGE_BUCKET'),
    iosBundleId: _env('FIREBASE_IOS_BUNDLE_ID'),
  );

  // ═══════════════════════════════════════════════════════════
  // macOS Configuration
  // ═══════════════════════════════════════════════════════════
  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: _env('FIREBASE_IOS_API_KEY'),
    appId: _env('FIREBASE_IOS_APP_ID'),
    messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _env('FIREBASE_PROJECT_ID'),
    storageBucket: _env('FIREBASE_STORAGE_BUCKET'),
    iosBundleId: _env('FIREBASE_IOS_BUNDLE_ID'),
  );
}
