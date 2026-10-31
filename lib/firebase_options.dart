

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
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBF8PNol118xYc8AMbhQKdx_JX7opzuapQ',
    appId: '1:218133252419:ios:579b3e9a2cac128864c7f6',
    messagingSenderId: '218133252419',
    projectId: 'fottballlove-25dbe',
    storageBucket: 'fottballlove-25dbe.firebasestorage.app',
    iosBundleId: 'com.example.flutterAiApp',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBF8PNol118xYc8AMbhQKdx_JX7opzuapQ',
    appId: '1:218133252419:ios:579b3e9a2cac128864c7f6',
    messagingSenderId: '218133252419',
    projectId: 'fottballlove-25dbe',
    storageBucket: 'fottballlove-25dbe.firebasestorage.app',
    iosBundleId: 'com.example.flutterAiApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAJ_9flZ1qRMNABXoJleLVF2_djSJ0wvOA',
    appId: '1:218133252419:web:92cda0d59f7b75e464c7f6',
    messagingSenderId: '218133252419',
    projectId: 'fottballlove-25dbe',
    authDomain: 'fottballlove-25dbe.firebaseapp.com',
    storageBucket: 'fottballlove-25dbe.firebasestorage.app',
    measurementId: 'G-JJZPVJ0Q2W',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAJ_9flZ1qRMNABXoJleLVF2_djSJ0wvOA',
    appId: '1:218133252419:web:92cda0d59f7b75e464c7f6',
    messagingSenderId: '218133252419',
    projectId: 'fottballlove-25dbe',
    authDomain: 'fottballlove-25dbe.firebaseapp.com',
    storageBucket: 'fottballlove-25dbe.firebasestorage.app',
    measurementId: 'G-JJZPVJ0Q2W',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAgUuIQON7c4gHbmoUqhgGOjBCa5hlKqtY',
    appId: '1:218133252419:android:9282443d75932fe564c7f6',
    messagingSenderId: '218133252419',
    projectId: 'fottballlove-25dbe',
    storageBucket: 'fottballlove-25dbe.firebasestorage.app',
  );
}
