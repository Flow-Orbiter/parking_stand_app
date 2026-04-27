// Wygenerowane FlutterFire (projekt: mdm-sport, platformy: web, android, ios).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Opcje z konsoli Firebase (web, android, iOS).
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
      default:
        throw UnsupportedError('Brak domyślnych FirebaseOptions dla tej platformy.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAoHWoHx5mKwgAQC97aJmAwuMX8KEBPwyM',
    appId: '1:435452635733:web:c6fb3363fdca8a488a82dc',
    messagingSenderId: '435452635733',
    projectId: 'mdm-sport',
    authDomain: 'mdm-sport.firebaseapp.com',
    databaseURL: 'https://mdm-sport-default-rtdb.firebaseio.com',
    storageBucket: 'mdm-sport.firebasestorage.app',
    measurementId: 'G-RVJ47KTQJG',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCGqFkHQMJERUe0UGSnGl-64UgRaBGACvA',
    appId: '1:435452635733:android:96bc888e2be239cb8a82dc',
    messagingSenderId: '435452635733',
    projectId: 'mdm-sport',
    databaseURL: 'https://mdm-sport-default-rtdb.firebaseio.com',
    storageBucket: 'mdm-sport.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyATn4G1U9KNfhzIYT6xJOz9ZDe_IS9RuC4',
    appId: '1:435452635733:ios:5bc797e2c6a986be8a82dc',
    messagingSenderId: '435452635733',
    projectId: 'mdm-sport',
    databaseURL: 'https://mdm-sport-default-rtdb.firebaseio.com',
    storageBucket: 'mdm-sport.firebasestorage.app',
    androidClientId: '435452635733-4t8m4ji2irmj292mdufrc51ge84khlk4.apps.googleusercontent.com',
    iosClientId: '435452635733-8afefeug7h2d9bui5e08ad6omfo94cvs.apps.googleusercontent.com',
    iosBundleId: 'com.floworbiter.baps',
  );

}