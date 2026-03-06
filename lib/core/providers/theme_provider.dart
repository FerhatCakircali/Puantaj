import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ThemeStateNotifier - Tema modunu yöneten Notifier.
/// Bu sınıf, uygulamanın tema modunu (light/dark/system) yönetir ve
/// SharedPreferences ile kalıcı hale getirir.
/// **Özellikler:**
/// - Light, Dark, System tema modları
/// - SharedPreferences ile kalıcı saklama
/// - Tema değişikliklerini dinleme
/// - Mevcut themeModeNotifier ile paralel çalışır (backward compatibility)
/// **Kullanım:**
/// ```dart
/// // Tema modunu okuma
/// final themeMode = ref.watch(themeStateProvider);
/// // Tema değiştirme
/// ref.read(themeStateProvider.notifier).setTheme(ThemeMode.dark);
/// ```
/// Saat Dilimi: Europe/Istanbul (UTC+3)
class ThemeStateNotifier extends Notifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';

  /// Başlangıç durumu - SharedPreferences'tan yükle veya system kullan
  @override
  ThemeMode build() {
    _loadSavedTheme();
    return ThemeMode.system;
  }

  /// Kaydedilmiş tema tercihini yükler.
    /// SharedPreferences'tan tema modunu okur ve state'i günceller.
  /// Eğer kaydedilmiş tema yoksa, system modunu kullanır.
  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      if (savedTheme != null) {
        switch (savedTheme) {
          case 'dark':
            state = ThemeMode.dark;
            break;
          case 'light':
            state = ThemeMode.light;
            break;
          case 'system':
            state = ThemeMode.system;
            break;
        }
      }
    } catch (e) {
      // Hata durumunda system modunu kullan
      state = ThemeMode.system;
    }
  }

  /// Tema modunu ayarlar ve SharedPreferences'a kaydeder.
    /// Parametreler:
  /// - [themeMode]: Yeni tema modu (light, dark, system)
    /// Örnek:
  /// ```dart
  /// // Koyu tema
  /// ref.read(themeStateProvider.notifier).setTheme(ThemeMode.dark);
    /// // Açık tema
  /// ref.read(themeStateProvider.notifier).setTheme(ThemeMode.light);
    /// // Sistem teması
  /// ref.read(themeStateProvider.notifier).setTheme(ThemeMode.system);
  /// ```
  Future<void> setTheme(ThemeMode themeMode) async {
    try {
      // State'i güncelle
      state = themeMode;

      // SharedPreferences'a kaydet
      final prefs = await SharedPreferences.getInstance();
      String themeString;

      switch (themeMode) {
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.system:
          themeString = 'system';
          break;
      }

      await prefs.setString(_themeKey, themeString);
    } catch (e) {
      // Hata durumunda sadece state'i güncelle
      state = themeMode;
    }
  }

  /// Koyu temaya geçer.
    /// Örnek:
  /// ```dart
  /// ref.read(themeStateProvider.notifier).setDarkTheme();
  /// ```
  Future<void> setDarkTheme() async {
    await setTheme(ThemeMode.dark);
  }

  /// Açık temaya geçer.
    /// Örnek:
  /// ```dart
  /// ref.read(themeStateProvider.notifier).setLightTheme();
  /// ```
  Future<void> setLightTheme() async {
    await setTheme(ThemeMode.light);
  }

  /// Sistem temasına geçer.
    /// Örnek:
  /// ```dart
  /// ref.read(themeStateProvider.notifier).setSystemTheme();
  /// ```
  Future<void> setSystemTheme() async {
    await setTheme(ThemeMode.system);
  }

  /// Tema modunu toggle eder (light ↔ dark).
    /// System modundaysa dark'a geçer.
    /// Örnek:
  /// ```dart
  /// ref.read(themeStateProvider.notifier).toggleTheme();
  /// ```
  Future<void> toggleTheme() async {
    switch (state) {
      case ThemeMode.light:
        await setTheme(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setTheme(ThemeMode.light);
        break;
      case ThemeMode.system:
        await setTheme(ThemeMode.dark);
        break;
    }
  }
}

/// ThemeStateProvider - Tema modunu sağlayan global provider.
/// Bu provider, uygulamanın her yerinden tema moduna erişim sağlar.
/// **Kullanım Örnekleri:**
/// ```dart
/// // Widget içinde tema modunu dinleme
/// class MyApp extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final themeMode = ref.watch(themeStateProvider);
///     return MaterialApp(
///       themeMode: themeMode,
///       // ...
///     );
///   }
/// }
/// // Tema değiştirme butonu
/// ElevatedButton(
///   onPressed: () {
///     ref.read(themeStateProvider.notifier).toggleTheme();
///   },
///   child: Text('Tema Değiştir'),
/// );
/// ```
final themeStateProvider = NotifierProvider<ThemeStateNotifier, ThemeMode>(() {
  return ThemeStateNotifier();
});
