import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;

  final NotificationService _notificationService = NotificationService();

  BackgroundService._internal();

  // Arka plan görevini başlat
  Future<void> initializeBackgroundTask() async {
    try {
      // Workmanager'ı başlat
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      // Periyodik görevi kaydet
      await Workmanager().registerOneOffTask(
        "notificationCheckTask",
        DateTime.now()
            .add(Duration(minutes: 15))
            .millisecondsSinceEpoch
            .toString(), // 15 dakika sonra
        existingWorkPolicy: ExistingWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.exponential,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresCharging: false,
          requiresDeviceIdle: false,
        ),
      );

      print('Arka plan görevi başarıyla başlatıldı');
    } catch (e) {
      print('Arka plan görevi başlatılırken hata: $e');
    }
  }

  // Periyodik bildirim kontrolü görevi
  Future<void> startPeriodicNotificationCheck() async {
    try {
      await Workmanager().registerPeriodicTask(
        "periodicNotificationCheck",
        Duration(hours: 1).inMilliseconds.toString(), // Her saat
        existingWorkPolicy: ExistingWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.exponential,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresCharging: false,
          requiresDeviceIdle: false,
        ),
      );

      print('Periyodik bildirim kontrolü başlatıldı');
    } catch (e) {
      print('Periyodik bildirim kontrolü başlatılırken hata: $e');
    }
  }

  // Workmanager callback fonksiyonu
  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((taskName, inputData) async {
      try {
        print('Arka plan görevi çalıştırılıyor: $taskName');

        // Bildirim servisini başlat
        final notificationService = NotificationService();

        switch (taskName) {
          case "notificationCheckTask":
          case "periodicNotificationCheck":
            await notificationService.checkAndRescheduleNotifications();
            break;
          default:
            print('Bilinmeyen görev: $taskName');
        }

        return Future.value(true);
      } catch (e) {
        print('Arka plan görevi çalıştırılırken hata: $e');
        return Future.value(false);
      }
    });
  }

  // Uygulama açıldığında bildirimleri kontrol et
  Future<void> checkNotificationsOnAppStart() async {
    try {
      await _notificationService.checkAndRescheduleNotifications();
    } catch (e) {
      print('Bildirimler kontrol edilirken hata: $e');
    }
  }

  // Uygulama kapatıldığında bildirimleri koru
  Future<void> preserveNotificationsOnAppClose() async {
    try {
      // Mevcut zamanlanmış bildirimleri kontrol et
      final pendingNotifications = await _notificationService
          .getPendingNotifications();
      print(
        'Uygulama kapatılırken mevcut bildirim sayısı: ${pendingNotifications.length}',
      );

      // Arka plan görevini başlat
      await initializeBackgroundTask();
    } catch (e) {
      print('Uygulama kapatılırken hata: $e');
    }
  }
}
