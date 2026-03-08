import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';

/// Bildirim izinlerini yöneten mixin
///
/// Android ve iOS platformları için bildirim izinlerini kontrol eder ve ister.
/// Android 13+ için POST_NOTIFICATIONS, Android 12+ için SCHEDULE_EXACT_ALARM izinlerini yönetir.
mixin NotificationPermissionMixin {
  /// Bildirim izinlerini kontrol eder ve gerekirse ister
  ///
  /// Platform bazlı izin kontrolü yapar:
  /// - Android: POST_NOTIFICATIONS ve SCHEDULE_EXACT_ALARM
  /// - iOS: Bildirim izni (alert, badge, sound)
  ///
  /// Returns: İzinler verilirse true, reddedilirse false
  Future<bool> checkAndRequestPermissions() async {
    try {
      if (Platform.isAndroid) {
        return await _checkAndRequestAndroidPermissions();
      } else if (Platform.isIOS) {
        return await _checkAndRequestIOSPermissions();
      }

      debugPrint('Desteklenmeyen platform: ${Platform.operatingSystem}');
      return false;
    } catch (e, stackTrace) {
      debugPrint('Bildirim izinleri kontrol edilirken hata: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Android için bildirim izinlerini kontrol eder ve ister
  ///
  /// POST_NOTIFICATIONS (Android 13+) ve SCHEDULE_EXACT_ALARM (Android 12+) izinlerini kontrol eder.
  ///
  /// Returns: Tüm izinler verilirse true, herhangi biri reddedilirse false
  Future<bool> _checkAndRequestAndroidPermissions() async {
    try {
      final notificationGranted = await _requestNotificationPermission();
      if (!notificationGranted) {
        return false;
      }

      await _requestScheduleExactAlarmPermission();

      return true;
    } catch (e, stackTrace) {
      debugPrint('Android izinleri kontrol edilirken hata: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// POST_NOTIFICATIONS iznini kontrol eder ve ister
  ///
  /// Returns: İzin verilirse true, reddedilirse false
  Future<bool> _requestNotificationPermission() async {
    final status = await Permission.notification.status;

    if (status.isGranted) {
      return true;
    }

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// SCHEDULE_EXACT_ALARM iznini kontrol eder ve gerekirse ayarlara yönlendirir
  ///
  /// Bu izin manuel olarak verilmesi gerektiğinden kullanıcıyı ayarlara yönlendirir.
  Future<void> _requestScheduleExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;

    if (status.isGranted) {
      return;
    }

    await openAppSettings();
    await Future.delayed(const Duration(seconds: 2));

    final newStatus = await Permission.scheduleExactAlarm.status;
    if (!newStatus.isGranted) {
      debugPrint(
        'SCHEDULE_EXACT_ALARM izni verilmedi. Hatırlatıcılar çalışmayabilir.',
      );
    }
  }

  /// Pil optimizasyonu iznini kontrol eder ve kullanıcıyı ayarlara yönlendirir
  ///
  /// Bildirimlerin arka planda çalışması için pil optimizasyonunun kapatılması gerekir.
  /// Kullanıcıya bilgilendirme dialog'u gösterir ve onay alırsa ayarlara yönlendirir.
  ///
  /// [context] Dialog göstermek için gerekli BuildContext
  Future<void> requestBatteryOptimizationExemption(BuildContext context) async {
    if (!Platform.isAndroid) return;

    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (status.isGranted) {
        return;
      }

      if (!context.mounted) return;

      final shouldOpen = await _showBatteryOptimizationDialog(context);
      if (shouldOpen != true) return;

      if (!context.mounted) return;

      await _openBatteryOptimizationSettings();
    } catch (e) {
      debugPrint('Pil optimizasyonu kontrolü hatası: $e');
    }
  }

  /// Pil optimizasyonu bilgilendirme dialog'unu gösterir
  ///
  /// Returns: Kullanıcı ayarları açmak isterse true, aksi halde false
  Future<bool?> _showBatteryOptimizationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Arka Plan İzni Gerekli'),
        content: const Text(
          'Bildirimlerin arka planda çalışması için pil optimizasyonunu kapatmanız gerekiyor.\n\n'
          'Açılacak ayarlar sayfasında:\n'
          '1. "Pil kullanımını optimize et" seçeneğini bulun\n'
          '2. "Tüm uygulamalar" seçin\n'
          '3. Puantaj uygulamasını bulun\n'
          '4. "Optimize etme" seçeneğini seçin',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Daha Sonra'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ayarları Aç'),
          ),
        ],
      ),
    );
  }

  /// Pil optimizasyonu ayarlarını açar
  Future<void> _openBatteryOptimizationSettings() async {
    try {
      const intent = AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
      );
      await intent.launch();
    } catch (e) {
      debugPrint('Pil optimizasyonu ayarları açılamadı: $e');
      await openAppSettings();
    }
  }

  /// Otomatik başlatma iznini kontrol eder ve kullanıcıyı ayarlara yönlendirir
  ///
  /// Xiaomi/MIUI cihazlarda bildirimlerin düzgün çalışması için gereklidir.
  /// Kullanıcıya bilgilendirme dialog'u gösterir ve onay alırsa ayarlara yönlendirir.
  ///
  /// [context] Dialog göstermek için gerekli BuildContext
  Future<void> requestAutoStartPermission(BuildContext context) async {
    if (!Platform.isAndroid) return;

    try {
      if (!context.mounted) return;

      final shouldOpen = await _showAutoStartDialog(context);
      if (shouldOpen != true) return;

      if (!context.mounted) return;

      await _openAutoStartSettings();
    } catch (e) {
      debugPrint('Otomatik başlatma kontrolü hatası: $e');
    }
  }

  /// Otomatik başlatma bilgilendirme dialog'unu gösterir
  ///
  /// Returns: Kullanıcı ayarları açmak isterse true, aksi halde false
  Future<bool?> _showAutoStartDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Otomatik Başlatma İzni'),
        content: const Text(
          'Bildirimlerin düzgün çalışması için otomatik başlatma iznine ihtiyaç var.\n\n'
          'Xiaomi/MIUI cihazlarda:\n'
          '1. Güvenlik > İzinler > Otomatik başlatma\n'
          '2. Puantaj uygulamasını bulun\n'
          '3. Açık konuma getirin\n\n'
          'Diğer cihazlarda benzer ayarları arayın.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Daha Sonra'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ayarları Aç'),
          ),
        ],
      ),
    );
  }

  /// Otomatik başlatma ayarlarını açar
  Future<void> _openAutoStartSettings() async {
    try {
      const intent = AndroidIntent(
        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        data: 'package:com.example.puantaj',
      );
      await intent.launch();
    } catch (e) {
      debugPrint('Uygulama ayarları açılamadı: $e');
      await openAppSettings();
    }
  }

  /// Tüm gerekli izinleri ve ayarları kontrol eder
  ///
  /// Sırasıyla bildirim izinleri, pil optimizasyonu ve otomatik başlatma izinlerini kontrol eder.
  ///
  /// [context] Dialog göstermek için gerekli BuildContext
  Future<void> requestAllPermissionsAndSettings(BuildContext context) async {
    if (!Platform.isAndroid) return;

    try {
      final notificationGranted = await _checkAndRequestAndroidPermissions();
      if (!notificationGranted) {
        return;
      }

      if (!context.mounted) return;
      await requestBatteryOptimizationExemption(context);

      if (!context.mounted) return;
      await requestAutoStartPermission(context);
    } catch (e) {
      debugPrint('Tüm izinler kontrol edilirken hata: $e');
    }
  }

  /// iOS için bildirim izinlerini kontrol eder ve ister
  ///
  /// iOS'ta bildirim izni alert, badge ve sound yetkilerini içerir.
  ///
  /// Returns: İzin verilirse true, reddedilirse false
  Future<bool> _checkAndRequestIOSPermissions() async {
    try {
      final status = await Permission.notification.status;

      if (status.isGranted) {
        return true;
      }

      final result = await Permission.notification.request();
      return result.isGranted;
    } catch (e, stackTrace) {
      debugPrint('iOS izinleri kontrol edilirken hata: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
}
