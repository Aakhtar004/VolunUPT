import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static const String projectId = 'volunupt';
  static const String storageBucket = 'volunupt.firebasestorage.app';
  static const String messagingSenderId = '797331298645';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyDgTz6NrDqY-zJR6rC4phNzVE35IyEcNng',
        appId: '1:797331298645:web:3c818897e01afd3cba77dc',
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket,
        authDomain: 'volunupt.firebaseapp.com',
      );
    }

    if (Platform.isAndroid) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyDgTz6NrDqY-zJR6rC4phNzVE35IyEcNng',
        appId: '1:797331298645:android:3c818897e01afd3cba77dc',
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket,
      );
    }

    if (Platform.isIOS) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyDgTz6NrDqY-zJR6rC4phNzVE35IyEcNng',
        appId: '1:797331298645:ios:3c818897e01afd3cba77dc',
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket,
        iosBundleId: 'com.example.volunupt',
      );
    }

    throw UnsupportedError('Plataforma no soportada');
  }
}