import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'error_handler.dart';

/// Uygulama global değişkenleri ve helper fonksiyonları

// Auth durumunu tutan global değişken
final ValueNotifier<bool> authStateNotifier = ValueNotifier<bool>(false);

// Tema modunu tutan global değişken
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
  ThemeMode.system,
);

// Supabase istemcisine global erişim
late final SupabaseClient supabase;

// Bildirim gösterme işlemi için global anahtar
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// Drawer menüsünü açmak için global scaffold key
final GlobalKey<ScaffoldState> globalScaffoldKey = GlobalKey<ScaffoldState>();

/// Global bildirim fonksiyonu
void showGlobalSnackbar(String message, {Color backgroundColor = Colors.blue}) {
  try {
    final messenger = appScaffoldMessengerKey.currentState;
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
    }
  } catch (e, stack) {
    ErrorHandler.logError('showGlobalSnackbar', e, stack);
  }
}

/// Hata yakalama için global handler
void logError(String message, dynamic error, StackTrace? stackTrace) {
  ErrorHandler.logError(message, error, stackTrace);
}
