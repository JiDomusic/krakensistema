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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAW3u9v32Icc8LX_xWs4YNtGkwTDwLlFnY',
    authDomain: 'krakensitema.firebaseapp.com',
    projectId: 'krakensitema',
    storageBucket: 'krakensitema.firebasestorage.app',
    messagingSenderId: '534065732573',
    appId: '1:534065732573:web:971c27fadb4d7c590a3434',
    measurementId: 'G-XXXXXXXXXX', // <-- opcional,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAW3u9v32Icc8LX_xWs4YNtGkwTDwLlFnY',
    appId: '1:534065732573:web:971c27fadb4d7c590a3434',
    messagingSenderId: '534065732573',
    projectId: 'krakensitema',
    storageBucket: 'krakensitema.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAW3u9v32Icc8LX_xWs4YNtGkwTDwLlFnY',
    appId: '1:534065732573:web:971c27fadb4d7c590a3434',
    messagingSenderId: '534065732573',
    projectId: 'krakensitema',
    storageBucket: 'krakensitema.firebasestorage.app',
    iosClientId: '',
    iosBundleId: '',
  );
}
