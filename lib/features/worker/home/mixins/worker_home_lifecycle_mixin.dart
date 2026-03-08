import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/services/local_storage_service.dart';
import '../../../../services/notification_service.dart';
import '../../services/worker_notification_listener_service.dart';
import '../../services/worker_notification_service.dart';

/// Worker home ekranı lifecycle yönetimi
mixin WorkerHomeLifecycleMixin<T extends StatefulWidget> on State<T> {
  final localStorage = LocalStorageService.instance;
  StreamSubscription<String>? notificationClickSubscription;

  String? workerName;
  String? workerUsername;

  /// Auth kontrolü
  Future<void> checkAuth(BuildContext context) async {
    final session = await localStorage.getWorkerSession();
    if (session == null && mounted) {
      // ignore: use_build_context_synchronously
      context.go('/worker/login');
    } else if (session != null) {
      setState(() {
        workerName = session['fullName'];
        workerUsername = session['username'];
      });
    }
  }

  /// Bildirim listener'ı başlat
  Future<void> startNotificationListener() async {
    try {
      final session = await localStorage.getWorkerSession();
      if (session != null) {
        final workerId = int.parse(session['workerId']!);
        await WorkerNotificationListenerService.instance.startListening(
          workerId,
        );
      }
    } catch (e) {
      debugPrint('Bildirim dinleme başlatılamadı: $e');
    }
  }

  /// Bildirim listener'ı durdur
  Future<void> stopNotificationListener() async {
    try {
      await WorkerNotificationListenerService.instance.stopListening();
    } catch (e) {
      debugPrint('Bildirim dinleme durdurulurken hata: $e');
    }
  }

  /// Bildirim tıklama stream'ini dinle
  void setupNotificationClickListener(VoidCallback onNotificationClick) {
    // Stream import edilmediği için bu kısım ana dosyada kalmalı
  }

  /// Lifecycle başlangıç
  void initializeLifecycle(
    BuildContext context,
    VoidCallback onNotificationClick,
  ) {
    checkAuth(context);
    startNotificationListener();
    
    // Uygulama başlangıcında bildirimleri kontrol et
    _checkAndRescheduleNotifications();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        onNotificationClick();
      }
    });

    setupNotificationClickListener(onNotificationClick);
  }

  /// Lifecycle temizleme
  void cleanupLifecycle() {
    notificationClickSubscription?.cancel();
    stopNotificationListener();
  }

  /// Bildirimleri kontrol et ve yeniden zamanla
  Future<void> _checkAndRescheduleNotifications() async {
    try {
      final notificationService = NotificationService();
      await notificationService.checkAndRescheduleNotifications();
      debugPrint('Bildirimler yeniden zamanlandı (worker)');
    } catch (e) {
      debugPrint('Bildirimler yeniden zamanlanırken hata: $e');
    }
  }

  /// Bekleyen bildirimi kontrol eder ve uygun yönlendirmeyi yapar
  Future<void> handlePendingNotification(
    BuildContext context,
    Function(int) onTabChange,
  ) async {
    try {
      debugPrint('📭 WorkerHomeScreen: Bekleyen bildirim kontrol ediliyor...');

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final hasPending = prefs.getBool('has_pending_notification') ?? false;

      if (!hasPending) {
        debugPrint('📭 WorkerHomeScreen: Bekleyen bildirim yok');
        return;
      }

      final workerNotificationType = prefs.getString(
        'worker_notification_type',
      );

      debugPrint('📭 WorkerHomeScreen: Bildirim tipi: $workerNotificationType');

      if (workerNotificationType != null) {
        switch (workerNotificationType) {
          case 'attendance_approved':
          case 'attendance_rejected':
          case 'attendance_reminder':
            debugPrint(
              '✅ WorkerHomeScreen: Hatırlatıcılar sayfasına yönlendiriliyor (tab 3)...',
            );

            onTabChange(3);

            await prefs.remove('worker_notification_type');
            await prefs.remove('worker_notification_id');
            await prefs.setBool('has_pending_notification', false);

            debugPrint(
              '✅ WorkerHomeScreen: Hatırlatıcılar sayfasına yönlendirme başarılı',
            );
            break;
          case 'payment_received':
            debugPrint(
              '✅ WorkerHomeScreen: Geçmiş sayfasına (Ödeme Geçmişi) yönlendiriliyor (tab 1)...',
            );

            onTabChange(1);

            await prefs.setInt('worker_attendance_initial_tab', 1);

            await prefs.remove('worker_notification_type');
            await prefs.remove('worker_notification_id');
            await prefs.setBool('has_pending_notification', false);

            debugPrint(
              '✅ WorkerHomeScreen: Geçmiş sayfasına (Ödeme Geçmişi sekmesi) yönlendirme başarılı',
            );
            break;
          case 'payment_updated':
          case 'payment_deleted':
            debugPrint(
              '✅ WorkerHomeScreen: Bildirimler sayfasına yönlendiriliyor...',
            );

            onTabChange(2);

            await prefs.remove('worker_notification_type');
            await prefs.remove('worker_notification_id');
            await prefs.setBool('has_pending_notification', false);

            debugPrint(
              '✅ WorkerHomeScreen: Bildirimler sayfasına yönlendirme başarılı',
            );
            break;
          default:
            debugPrint(
              '⚠️ WorkerHomeScreen: Bilinmeyen bildirim tipi: $workerNotificationType',
            );
        }
      } else {
        if (mounted) {
          final notificationService = NotificationService();
          // ignore: use_build_context_synchronously
          await notificationService.checkAndHandlePendingNotification(context);
        }
      }

      debugPrint('WorkerHomeScreen: Bildirim kontrolü tamamlandı');
    } catch (e, stackTrace) {
      debugPrint('WorkerHomeScreen: Bildirim yönlendirmesi hatası: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Çıkış işlemi
  Future<void> handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hayır'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await stopNotificationListener();

      try {
        final session = await localStorage.getWorkerSession();
        if (session != null) {
          final workerId = int.parse(session['workerId']!);
          final workerNotificationService = WorkerNotificationService();
          await workerNotificationService.cancelWorkerAttendanceReminder(
            workerId,
          );
          debugPrint('Çalışan hatırlatıcısı iptal edildi');
        }
      } catch (e) {
        debugPrint('Çalışan hatırlatıcısı iptal edilirken hata: $e');
      }

      await localStorage.clearWorkerSession();
      if (mounted) {
        // ignore: use_build_context_synchronously
        context.go('/login');
      }
    }
  }
}
