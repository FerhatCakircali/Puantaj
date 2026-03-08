import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Worker home ekranı iş mantığı
mixin WorkerHomeLogicMixin<T extends StatefulWidget> on State<T> {
  int selectedIndex = 0;

  /// Seçili index'i yükle
  Future<void> loadSelectedIndex(int? initialTab, int screensLength) async {
    if (initialTab != null) {
      final safeIndex = initialTab.clamp(0, screensLength - 1);
      setState(() => selectedIndex = safeIndex);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('worker_selected_index') ?? 0;
    final safeIndex = savedIndex.clamp(0, screensLength - 1);
    if (mounted) {
      setState(() => selectedIndex = safeIndex);
    }
  }

  /// Seçili index'i kaydet
  Future<void> saveSelectedIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('worker_selected_index', index);
  }

  /// Tab değiştir
  void onItemTapped(BuildContext context, int index, int screensLength) {
    final safeIndex = index.clamp(0, screensLength - 1);
    setState(() => selectedIndex = safeIndex);
    saveSelectedIndex(safeIndex);
    Navigator.pop(context);
  }

  /// Tema modunu kaydet
  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.dark:
        await prefs.setString('theme_mode', 'dark');
        break;
      case ThemeMode.light:
        await prefs.setString('theme_mode', 'light');
        break;
      case ThemeMode.system:
        await prefs.setString('theme_mode', 'system');
        break;
    }
  }

  /// Tema değiştir (animasyonlu)
  Future<void> toggleThemeWithAnimation(
    BuildContext context,
    GlobalKey themeIconKey,
  ) async {
    // Bu fonksiyon artık kullanılmamalı
    // Widget'ı ConsumerStatefulWidget'a çevirip ThemeProvider kullanın
    throw UnimplementedError(
      'Convert widget to ConsumerStatefulWidget and use ThemeProvider',
    );
  }
}
