// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyChanXgxaGPzSSv_zML9iAcldjdot5aIsQ',
    appId: '1:267223687057:web:2cb7ffe2a63460e7f58430',
    messagingSenderId: '267223687057',
    projectId: 'smart-switch-pblin2024',
    authDomain: 'smart-switch-pblin2024.firebaseapp.com',
    storageBucket: 'smart-switch-pblin2024.firebasestorage.app',
    measurementId: 'G-F9ZEZPWGH7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD15JQa9cvOrwY0K9_FRjWk3es4i38WExg',
    appId: '1:145953908614:android:e8a276fc9ba56fc9a92e07',
    messagingSenderId: '145953908614',
    projectId: 'smart-switch-pbl-in2024-db81c',
    storageBucket: 'smart-switch-pbl-in2024-db81c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBaNkaLSTE5g-wfJtOlXppwew-9xqOSuGg',
    appId: '1:267223687057:ios:fa03fa207bdb88cdf58430',
    messagingSenderId: '267223687057',
    projectId: 'smart-switch-pblin2024',
    storageBucket: 'smart-switch-pblin2024.firebasestorage.app',
    iosBundleId: 'com.example.adminSmartSwitch',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBaNkaLSTE5g-wfJtOlXppwew-9xqOSuGg',
    appId: '1:267223687057:ios:fa03fa207bdb88cdf58430',
    messagingSenderId: '267223687057',
    projectId: 'smart-switch-pblin2024',
    storageBucket: 'smart-switch-pblin2024.firebasestorage.app',
    iosBundleId: 'com.example.adminSmartSwitch',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyChanXgxaGPzSSv_zML9iAcldjdot5aIsQ',
    appId: '1:267223687057:web:82e4ba0a5265290af58430',
    messagingSenderId: '267223687057',
    projectId: 'smart-switch-pblin2024',
    authDomain: 'smart-switch-pblin2024.firebaseapp.com',
    storageBucket: 'smart-switch-pblin2024.firebasestorage.app',
    measurementId: 'G-KWL8Y1T0KM',
  );
}