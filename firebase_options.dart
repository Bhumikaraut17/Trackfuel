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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAxPgoW15PWgarwi-Xw9RSFBirh4ptnMOs',
    appId: '1:318534813649:web:3452320ccf5417a18402f0',
    messagingSenderId: '318534813649',
    projectId: 'trackfuel-393f3',
    authDomain: 'trackfuel-393f3.firebaseapp.com',
    storageBucket: 'trackfuel-393f3.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAxPgoW15PWgarwi-Xw9RSFBirh4ptnMOs',
    appId: '1:318534813649:android:3452320ccf5417a18402f0',
    messagingSenderId: '318534813649',
    projectId: 'trackfuel-393f3',
    storageBucket: 'trackfuel-393f3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDrRfHn43fpwx2LfEHdqIfnicFk-kCwioA',
    appId: '1:318534813649:ios:fb94622686e8e3768402f0',
    messagingSenderId: '318534813649',
    projectId: 'trackfuel-393f3',
    storageBucket: 'trackfuel-393f3.firebasestorage.app',
    iosClientId: '318534813649-942275hhkkko35ohsldmu9vvsqnshol9.apps.googleusercontent.com',
    iosBundleId: 'com.example.trackfuel',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDrRfHn43fpwx2LfEHdqIfnicFk-kCwioA',
    appId: '1:318534813649:ios:fb94622686e8e3768402f0',
    messagingSenderId: '318534813649',
    projectId: 'trackfuel-393f3',
    storageBucket: 'trackfuel-393f3.firebasestorage.app',
    iosClientId: '318534813649-942275hhkkko35ohsldmu9vvsqnshol9.apps.googleusercontent.com',
    iosBundleId: 'com.example.trackfuel',
  );
} 