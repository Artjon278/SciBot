// File generated manually for Firebase configuration.
// Replace the values below with your actual Firebase project configuration.
//
// To get these values:
// 1. Go to Firebase Console (https://console.firebase.google.com)
// 2. Select your project → Project Settings (gear icon)
// 3. Scroll down to "Your apps" section
// 4. Copy the configuration values for each platform

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
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
        return web; // Use web config for Windows
      case TargetPlatform.linux:
        return web; // Use web config for Linux
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // WEB Configuration
  // ═══════════════════════════════════════════════════════════
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDXdAwy6aC71flegfojtMWVHG7dr9BqjIE',
    appId: '1:952847155396:web:5858d67508e62fd4f68991',
    messagingSenderId: '952847155396',
    projectId: 'scibot-1ab3c',
    authDomain: 'scibot-1ab3c.firebaseapp.com',
    storageBucket: 'scibot-1ab3c.firebasestorage.app',
    measurementId: 'G-VDDHDL8RM8',
  );

  // ═══════════════════════════════════════════════════════════
  // ANDROID Configuration
  // ═══════════════════════════════════════════════════════════
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA9RIqIxLUCfts1QdvcmT3t2ssldvXznpw',
    appId: '1:952847155396:android:f93409813d3c104cf68991',
    messagingSenderId: '952847155396',
    projectId: 'scibot-1ab3c',
    storageBucket: 'scibot-1ab3c.firebasestorage.app',
  );

  // ═══════════════════════════════════════════════════════════
  // iOS Configuration
  // Will be updated after adding iOS app in Firebase Console
  // ═══════════════════════════════════════════════════════════
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDXdAwy6aC71flegfojtMWVHG7dr9BqjIE',
    appId: '1:952847155396:web:5858d67508e62fd4f68991',
    messagingSenderId: '952847155396',
    projectId: 'scibot-1ab3c',
    storageBucket: 'scibot-1ab3c.firebasestorage.app',
    iosBundleId: 'com.example.scibot',
  );

  // ═══════════════════════════════════════════════════════════
  // macOS Configuration (same as iOS usually)
  // ═══════════════════════════════════════════════════════════
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDXdAwy6aC71flegfojtMWVHG7dr9BqjIE',
    appId: '1:952847155396:web:5858d67508e62fd4f68991',
    messagingSenderId: '952847155396',
    projectId: 'scibot-1ab3c',
    storageBucket: 'scibot-1ab3c.firebasestorage.app',
    iosBundleId: 'com.example.scibot',
  );
}
