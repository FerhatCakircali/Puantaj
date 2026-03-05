import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/database_cleanup_service.dart';
import '../../../../core/user_data_notifier.dart';
import '../../../../core/app_globals.dart';
import '../../../auth/login/screens/login_screen.dart';
import '../../services/employee_reminder_service.dart';
import 'home_notification_handler.dart';

/// Ana ekran lifecycle yönetimi mixin'i
mixin HomeLifecycleMixin<T extends StatefulWidget> on State<T>
    implements WidgetsBindingObserver {
  Timer? blockCheckTimer;
  bool tabStateInitialized = false;

  final AuthService authService = AuthService();
  final HomeNotificationHandler notificationHandler = HomeNotificationHandler();

  ValueNotifier<int?>? get selectedIndexNotifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    userDataNotifier.addListener(updateDrawerHeader);
    authService.currentUser;

    checkUserBlockStatus();
    blockCheckTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => checkUserBlockStatus(),
    );

    // Bildirim dinleme servisini başlat
    notificationHandler.startNotificationListener();

    // Eski hatırlatıcıları temizle
    _cleanupOldReminders();

    // Veritabanı temizliği yap
    _cleanupDatabase();

    // Ekran çizildikten sonra sekme durumunu başlat
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        initializeTabState();
      }
    });
  }

  /// Eski hatırlatıcıları temizle (3 gün geçmiş olanlar)
  Future<void> _cleanupOldReminders() async {
    try {
      final reminderService = EmployeeReminderService();
      final oldCount = await reminderService.cleanupOldReminders();
      final completedCount = await reminderService.cleanupCompletedReminders();

      debugPrint('🧹 Hatırlatıcı temizliği tamamlandı:');
      debugPrint('  - Eski: $oldCount');
      debugPrint('  - Tamamlanmış: $completedCount');
    } catch (e) {
      debugPrint('❌ Eski hatırlatıcılar temizlenirken hata: $e');
    }
  }

  /// Veritabanı temizliği yap
  Future<void> _cleanupDatabase() async {
    try {
      final cleanupService = DatabaseCleanupService();
      await cleanupService.performFullCleanup();
    } catch (e) {
      debugPrint('❌ Veritabanı temizlenirken hata: $e');
    }
  }

  @override
  void dispose() {
    notificationHandler.stopNotificationListener();
    WidgetsBinding.instance.removeObserver(this);
    blockCheckTimer?.cancel();
    userDataNotifier.removeListener(updateDrawerHeader);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Ön plana gelince kullanıcı verilerini yenile
      authService.loadCurrentUser();
      // Blok durumunu kontrol et
      checkUserBlockStatus();
    }
  }

  void signOut() async {
    await AuthService().signOut();
    authStateNotifier.value = false;

    if (!mounted) return;

    try {
      GoRouter.of(context).go('/login');
    } catch (e) {
      debugPrint('Login yönlendirme hatası: $e');
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  /// Kullanıcı verileri yüklendiğinde veya değiştiğinde Drawer başlığını güncelle
  void updateDrawerHeader() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Kullanıcının bloklu olup olmadığını kontrol eder
  Future<void> checkUserBlockStatus() async {
    try {
      final isBlocked = await authService.isUserBlocked();
      if (isBlocked && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bu hesap yönetici tarafından engellenmiştir. Lütfen iletişime geçin: ferhatcakircali@gmail.com',
            ),
            duration: Duration(seconds: 10),
            backgroundColor: Colors.red,
          ),
        );

        Future.delayed(const Duration(seconds: 10), () {
          if (mounted) {
            signOut();
          }
        });
      }
    } catch (e) {
      debugPrint('Kullanıcı blok durumu kontrolünde hata: $e');
    }
  }

  /// Sekme durumunu doğru öncelik sırasıyla başlatan fonksiyon
  Future<void> initializeTabState();
}
