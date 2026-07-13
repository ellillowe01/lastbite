// File konfigurasi Firebase — INI PLACEHOLDER, belum tersambung ke project
// Firebase manapun. Fitur login/sinkronisasi cloud akan nonaktif otomatis
// sampai file ini diganti dengan yang asli.
//
// Cara mengaktifkan:
//   1. dart pub global activate flutterfire_cli
//   2. flutterfire configure
//   (butuh login akun Google/Firebase kamu sendiri lewat browser)
// Perintah itu akan menimpa file ini dengan kredensial project Firebase asli,
// dan otomatis menambahkan config native yang dibutuhkan (mis. google-services.json).
//
// Jangan commit API key Firebase asli ke repo publik tanpa App Check / rules
// yang memadai — API key Firebase aman untuk client apps (bukan secret),
// tapi tetap batasi akses lewat Firestore Security Rules.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static const String _placeholder = 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE';

  /// True kalau file ini sudah diganti hasil `flutterfire configure`.
  static bool get isConfigured => android.apiKey != _placeholder;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk platform ini. '
          'Jalankan `flutterfire configure` untuk menambahkannya.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _placeholder,
    appId: _placeholder,
    messagingSenderId: _placeholder,
    projectId: _placeholder,
    authDomain: _placeholder,
    storageBucket: _placeholder,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD9eSa7Kk0ONyQYUrh4Svn9-GQQeFmh6PU',
    appId: '1:849959450481:android:77c2a7537887a5428128d0',
    messagingSenderId: '849959450481',
    projectId: 'lastbite-yo',
    storageBucket: 'lastbite-yo.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _placeholder,
    appId: _placeholder,
    messagingSenderId: _placeholder,
    projectId: _placeholder,
    storageBucket: _placeholder,
    iosBundleId: 'com.example.lastbite',
  );

  static const FirebaseOptions macos = ios;

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: _placeholder,
    appId: _placeholder,
    messagingSenderId: _placeholder,
    projectId: _placeholder,
    storageBucket: _placeholder,
  );
}
