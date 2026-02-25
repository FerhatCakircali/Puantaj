import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/auth_service.dart';
import '../../../../core/user_data_notifier.dart';
import '../../../../core/app_globals.dart';
import '../../../auth/login/screens/login_screen.dart';
import 'home_notification_handler.dart';

/// Ana ekran lifecycle yönetimi mixin'i
mixin HomeLifecycleMixin<T extends StatefulWidget> on State<T>
    implements WidgetsBindingObserver {
  Timer? backgroundTimer;
  Timer? blockCheckTimer;
  static const int backgroundTimeoutMinutes = 5;
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

    // Ekran çizildikten sonra sekme durumunu başlat
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        initializeTabState();
      }
    });
  }

  @override
  void dispose() {
    notificationHandler.stopNotificationListener();
    WidgetsBinding.instance.removeObserver(this);
    backgroundTimer?.cancel();
    blockCheckTimer?.cancel();
    userDataNotifier.removeListener(updateDrawerHeader);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      backgroundTimer = Timer(
        const Duration(minutes: backgroundTimeoutMinutes),
        onSessionTimeout,
      );
    } else if (state == AppLifecycleState.resumed) {
      backgroundTimer?.cancel();
      checkUserBlockStatus();
    }
  }

  void onSessionTimeout() {
    signOut();
    if (mounted) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oturum süresi doldu, tekrar giriş yapınız.'),
          ),
        );
      });
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
