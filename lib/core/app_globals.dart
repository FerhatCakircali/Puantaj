import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// Kaydedilmiş tema tercihini yükle
Future<void> loadSavedThemeMode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_mode');

    if (savedTheme != null) {
      switch (savedTheme) {
        case 'dark':
          themeModeNotifier.value = ThemeMode.dark;
          break;
        case 'light':
          themeModeNotifier.value = ThemeMode.light;
          break;
        case 'system':
          themeModeNotifier.value = ThemeMode.system;
          break;
      }
      ErrorHandler.logDebug('ThemeLoad', 'Tema yüklendi: $savedTheme');
    }
  } catch (e, stack) {
    ErrorHandler.logError('loadSavedThemeMode', e, stack);
  }
}

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
