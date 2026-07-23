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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAnSjUNuv7DK5hA12Gw28LW2PY1tmYkOOI',
    appId: '1:441400530741:android:ffabde00990dc9e0e9de7c',
    messagingSenderId: '441400530741',
    projectId: 'transient-team-workspace',
    storageBucket: 'transient-team-workspace.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAWQ4OBuYDPaTFh4YKjXmulcW9a8LGXQYQ',
    appId: '1:441400530741:web:6083a602c6fc4c2fe9de7c',
    messagingSenderId: '441400530741',
    projectId: 'transient-team-workspace',
    authDomain: 'transient-team-workspace.firebaseapp.com',
    storageBucket: 'transient-team-workspace.firebasestorage.app',
    measurementId: 'G-2TCCVHZQ07',
  );
}
