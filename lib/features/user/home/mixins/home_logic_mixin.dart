import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/error_logger.dart';
import '../../../../widgets/theme_toggle_animation.dart';
import '../../../../services/auth_service.dart';
import 'home_notification_handler.dart';

/// Ana ekran business logic mixin'i
mixin HomeLogicMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final AuthService authService = AuthService();
  final HomeNotificationHandler notificationHandler = HomeNotificationHandler();

  ValueNotifier<int?>? get selectedIndexNotifier;
  int? get initialTab;

  Future<void> saveSelectedIndex(int idx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_tab_index', idx);
  }

  /// Tema değiştirme fonksiyonu
  void toggleTheme() async {
    final currentMode = ref.read(themeStateProvider);
    final newMode = currentMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;

    void onAnimationComplete() {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }

    // Riverpod provider ile tema değiştir
    ref.read(themeStateProvider.notifier).setTheme(newMode);

    await ThemeToggleAnimation.show(
      context,
      goingToDark: newMode == ThemeMode.dark,
      onAnimationComplete: onAnimationComplete,
    );
  }

  /// Tema tercihini kaydet
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

  /// Çıkış yap dialogunu gösterme fonksiyonu
  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hayır'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Dialog'u kapat
              Navigator.pop(dialogContext);

              try {
                // Bildirim dinleyicisini durdur
                await notificationHandler.stopNotificationListener();

                // Çıkış yap
                await authService.signOut();

                ref.read(authStateProvider.notifier).logout();

                debugPrint(
                  '✅ Çıkış işlemi tamamlandı, login ekranına yönlendiriliyor',
                );
              } catch (e, stackTrace) {
                ErrorLogger.instance.logError(
                  'HomeLogicMixin.showLogoutDialog - signOut hatası',
                  error: e,
                  stackTrace: stackTrace,
                );
                debugPrint('Çıkış işlemi sırasında hata: $e');

                // Hata durumunda bile login ekranına yönlendir
                if (mounted && context.mounted) {
                  context.go('/login');
                }
              }
            },
            child: const Text('Evet'),
          ),
        ],
      ),
    );
  }

  void onDrawerItemTap(int index) {
    if (selectedIndexNotifier != null) {
      selectedIndexNotifier!.value = index;
      saveSelectedIndex(index);
    }
    Navigator.pop(context);
  }

  /// Sekme durumunu doğru öncelik sırasıyla başlatan fonksiyon
  Future<void> initializeTabState() async {
    debugPrint('HomeScreen: initializeTabState başlatıldı');

    // ÖNCELİK 1: initialTab parametresi
    if (initialTab != null) {
      debugPrint('🎯 ÖNCELİK 1: initialTab parametresi bulundu: $initialTab');

      final tabIndex = initialTab!;
      if (tabIndex >= 0 && selectedIndexNotifier != null) {
        selectedIndexNotifier!.value = tabIndex;
        await saveSelectedIndex(tabIndex);
        debugPrint('HomeScreen: initialTab ile sekme $tabIndex açıldı');
        return;
      }
    }

    // ÖNCELİK 2: Bildirim kontrolü ve yönlendirme
    await notificationHandler.handlePendingNotification(context);

    // ÖNCELİK 3: Rota ile gelen extra verisini kontrol et
    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, dynamic> && extra.containsKey('tab')) {
      final tabIndex = extra['tab'] as int?;
      if (tabIndex != null && selectedIndexNotifier != null) {
        debugPrint(
          '🔗 ÖNCELİK 3: Rota extra parametresi bulundu: tab=$tabIndex',
        );
        selectedIndexNotifier!.value = tabIndex;
        await saveSelectedIndex(tabIndex);
        return;
      }
    }

    // ÖNCELİK 4: Varsayılan olarak son açık sekmeyi aç
    if (selectedIndexNotifier != null) {
      final prefs = await SharedPreferences.getInstance();
      final lastTabIndex = prefs.getInt('selected_tab_index') ?? 0;

      debugPrint('📂 ÖNCELİK 4: Son açık sekme (index $lastTabIndex) açılıyor');
      selectedIndexNotifier!.value = lastTabIndex;
    }
  }
}
