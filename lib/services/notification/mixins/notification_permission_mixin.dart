import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';

/// Bildirim izinlerini yöneten mixin
/// Bu mixin bildirim sisteminin çalışması için gerekli tüm izinleri kontrol eder ve ister.
/// Android ve iOS platformları için farklı izin yönetimi sağlar.
/// Sorumluluklar:
/// - POST_NOTIFICATIONS izni kontrolü ve isteme (Android 13+)
/// - SCHEDULE_EXACT_ALARM izni kontrolü ve isteme (Android 12+)
/// - iOS bildirim izni kontrolü ve isteme
/// - İzin durumlarını kontrol etme
/// - Hata yönetimi ve loglama
mixin NotificationPermissionMixin {
  /// Bildirim izinlerini kontrol eder ve gerekirse ister
    /// Bu metod tüm gerekli izinleri kontrol eder ve kullanıcıdan ister.
  /// İzinler verilmezse false döner ve bildirim sistemi çalışmaz.
    /// Android için:
  /// - POST_NOTIFICATIONS izni (Android 13+/API 33+)
  /// - SCHEDULE_EXACT_ALARM izni (Android 12+/API 31+)
    /// iOS için:
  /// - Bildirim izni (alert, badge, sound)
    /// Returns: İzinler verilirse true, reddedilirse false
  Future<bool> checkAndRequestPermissions() async {
    try {
      if (Platform.isAndroid) {
        return await _checkAndRequestAndroidPermissions();
      } else if (Platform.isIOS) {
        return await _checkAndRequestIOSPermissions();
      }

      // Desteklenmeyen platform
      debugPrint('Desteklenmeyen platform: ${Platform.operatingSystem}');
      return false;
    } catch (e, stackTrace) {
      debugPrint('Bildirim izinleri kontrol edilirken hata: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Android için bildirim izinlerini kontrol eder ve ister
    /// Android 13+ (API 33+) için POST_NOTIFICATIONS izni gereklidir.
  /// Android 12+ (API 31+) için SCHEDULE_EXACT_ALARM izni gereklidir.
    /// Returns: Tüm izinler verilirse true, herhangi biri reddedilirse false
  Future<bool> _checkAndRequestAndroidPermissions() async {
    try {
      // POST_NOTIFICATIONS izni (Android 13+/API 33+)
      final notificationStatus = await Permission.notification.status;

      if (!notificationStatus.isGranted) {
        debugPrint('POST_NOTIFICATIONS izni verilmemiş, isteniyor...');
        final result = await Permission.notification.request();

        if (!result.isGranted) {
          debugPrint('POST_NOTIFICATIONS izni reddedildi: $result');
          return false;
        }

        debugPrint('POST_NOTIFICATIONS izni verildi');
      } else {
        debugPrint('POST_NOTIFICATIONS izni zaten verilmiş');
      }

      // SCHEDULE_EXACT_ALARM izni (Android 12+/API 31+)
      final alarmStatus = await Permission.scheduleExactAlarm.status;

      if (!alarmStatus.isGranted) {
        debugPrint('SCHEDULE_EXACT_ALARM izni verilmemiş!');
        debugPrint('Kullanıcı ayarlardan manuel olarak vermelidir.');

        // Kullanıcıyı ayarlara yönlendir
        debugPrint('🔧 Ayarlar sayfası açılıyor...');
        await openAppSettings();

        debugPrint(
          'ℹ️ Ayarlar > Uygulamalar > Puantaj > Alarmlar ve hatırlatıcılar > İzin ver',
        );

        // Ayarlardan döndükten sonra tekrar kontrol et
        await Future.delayed(const Duration(seconds: 2));
        final newStatus = await Permission.scheduleExactAlarm.status;

        if (!newStatus.isGranted) {
          debugPrint('SCHEDULE_EXACT_ALARM izni hala verilmedi');
          debugPrint('Hatırlatıcılar çalışmayabilir!');
          // Yine de devam et, belki inexact alarm çalışır
        } else {
          debugPrint('SCHEDULE_EXACT_ALARM izni verildi!');
        }
      } else {
        debugPrint('SCHEDULE_EXACT_ALARM izni zaten verilmiş');
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('Android izinleri kontrol edilirken hata: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Kullanıcıyı pil optimizasyonu ayarlarına yönlendirir
  Future<void> requestBatteryOptimizationExemption(BuildContext context) async {
    if (!Platform.isAndroid) return;

    try {
      // Pil optimizasyonu durumunu kontrol et
      final ignoringBatteryOptimizations =
          await Permission.ignoreBatteryOptimizations.status;

      if (ignoringBatteryOptimizations.isGranted) {
        debugPrint('Pil optimizasyonu zaten devre dışı');
        return;
      }

      // Dialog göster
      final shouldOpen = await showDialog<bool>(
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

      if (shouldOpen == true) {
        // Pil optimizasyonu ayarlarını aç
        try {
          const intent = AndroidIntent(
            action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
          );
          await intent.launch();
          debugPrint('🔋 Pil optimizasyonu ayarları açıldı');
        } catch (e) {
          debugPrint('Pil optimizasyonu ayarları açılamadı: $e');
          // Genel ayarları aç
          await openAppSettings();
        }
      }
    } catch (e) {
      debugPrint('Pil optimizasyonu kontrolü hatası: $e');
    }
  }

  /// Kullanıcıyı otomatik başlatma ayarlarına yönlendirir (Xiaomi için)
  Future<void> requestAutoStartPermission(BuildContext context) async {
    if (!Platform.isAndroid) return;

    try {
      final shouldOpen = await showDialog<bool>(
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

      if (shouldOpen == true) {
        // Xiaomi otomatik başlatma ayarlarını açmayı dene
        try {
          const intent = AndroidIntent(
            action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
            data: 'package:com.example.puantaj',
          );
          await intent.launch();
          debugPrint('Uygulama ayarları açıldı');
        } catch (e) {
          debugPrint('Uygulama ayarları açılamadı: $e');
          await openAppSettings();
        }
      }
    } catch (e) {
      debugPrint('Otomatik başlatma kontrolü hatası: $e');
    }
  }

  /// Tüm gerekli izinleri ve ayarları kontrol edip kullanıcıyı yönlendirir
  Future<void> requestAllPermissionsAndSettings(BuildContext context) async {
    if (!Platform.isAndroid) return;

    try {
      // 1. Bildirim izinlerini al
      final notificationGranted = await _checkAndRequestAndroidPermissions();

      if (!notificationGranted) {
        debugPrint('Bildirim izinleri verilmedi');
        return;
      }

      // 2. Pil optimizasyonunu kapat
      await requestBatteryOptimizationExemption(context);

      // 3. Otomatik başlatma iznini al
      await requestAutoStartPermission(context);

      debugPrint('Tüm izin ve ayar kontrolleri tamamlandı');
    } catch (e) {
      debugPrint('Tüm izinler kontrol edilirken hata: $e');
    }
  }

  /// iOS için bildirim izinlerini kontrol eder ve ister
    /// iOS'ta bildirim izni alert, badge ve sound yetkilerini içerir.
    /// Returns: İzin verilirse true, reddedilirse false
  Future<bool> _checkAndRequestIOSPermissions() async {
    try {
      final notificationStatus = await Permission.notification.status;

      if (!notificationStatus.isGranted) {
        debugPrint('iOS bildirim izni verilmemiş, isteniyor...');
        final result = await Permission.notification.request();

        if (!result.isGranted) {
          debugPrint('iOS bildirim izni reddedildi: $result');
          return false;
        }

        debugPrint('iOS bildirim izni verildi');
      } else {
        debugPrint('iOS bildirim izni zaten verilmiş');
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('iOS izinleri kontrol edilirken hata: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Bildirim izinlerinin durumunu kontrol eder (istemeden)
    /// Bu metod sadece mevcut izin durumunu kontrol eder, kullanıcıdan izin istemez.
    /// Returns: İzinler verilmişse true, verilmemişse false
  Future<bool> checkPermissionStatus() async {
    try {
      if (Platform.isAndroid) {
        final notificationStatus = await Permission.notification.status;
        return notificationStatus.isGranted;
      } else if (Platform.isIOS) {
        final notificationStatus = await Permission.notification.status;
        return notificationStatus.isGranted;
      }

      return false;
    } catch (e) {
      debugPrint('İzin durumu kontrol edilirken hata: $e');
      return false;
    }
  }
}
