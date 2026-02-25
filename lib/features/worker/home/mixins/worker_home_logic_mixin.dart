import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/app_globals.dart';
import '../../../../widgets/theme_toggle_animation.dart';

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
    final currentMode = themeModeNotifier.value;
    final newMode = currentMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;

    void onAnimationComplete() {}

    final RenderBox? renderBox =
        themeIconKey.currentContext?.findRenderObject() as RenderBox?;
    Offset? iconCenter;
    if (renderBox != null) {
      final iconPosition = renderBox.localToGlobal(Offset.zero);
      final iconSize = renderBox.size;
      iconCenter =
          iconPosition + Offset(iconSize.width / 2, iconSize.height / 2);
    }

    themeModeNotifier.value = newMode;
    saveThemeMode(newMode);

    await ThemeToggleAnimation.show(
      context,
      goingToDark: newMode == ThemeMode.dark,
      onAnimationComplete: onAnimationComplete,
      center: iconCenter,
    );
  }
}
