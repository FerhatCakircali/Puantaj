import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

/// Firebase ve global hata yakalayıcıları başlatan sınıf
class FirebaseInitializer {
  /// Firebase'i başlatır ve hata yakalayıcıları kurar
  static Future<void> initialize() async {
    // Önce Firebase'i başlat
    await _initializeFirebase();

    // Sonra hata yakalayıcıları kur
    _setupCrashlyticsHandlers();
  }

  /// Firebase'i başlatır
  static Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  /// Crashlytics hata yakalayıcılarını kurar
  static void _setupCrashlyticsHandlers() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.exception}');
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Platform Dispatcher Error: $error');
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
}
