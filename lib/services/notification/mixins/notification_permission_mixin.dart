import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Bildirim izinlerini yöneten mixin
///
/// Bu mixin bildirim sisteminin çalışması için gerekli tüm izinleri kontrol eder ve ister.
/// Android ve iOS platformları için farklı izin yönetimi sağlar.
///
/// Sorumluluklar:
/// - POST_NOTIFICATIONS izni kontrolü ve isteme (Android 13+)
/// - SCHEDULE_EXACT_ALARM izni kontrolü ve isteme (Android 12+)
/// - iOS bildirim izni kontrolü ve isteme
/// - İzin durumlarını kontrol etme
/// - Hata yönetimi ve loglama
mixin NotificationPermissionMixin {
  /// Bildirim izinlerini kontrol eder ve gerekirse ister
  ///
  /// Bu metod tüm gerekli izinleri kontrol eder ve kullanıcıdan ister.
  /// İzinler verilmezse false döner ve bildirim sistemi çalışmaz.
  ///
  /// Android için:
  /// - POST_NOTIFICATIONS izni (Android 13+/API 33+)
  /// - SCHEDULE_EXACT_ALARM izni (Android 12+/API 31+)
  ///
  /// iOS için:
  /// - Bildirim izni (alert, badge, sound)
  ///
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
  ///
  /// Android 13+ (API 33+) için POST_NOTIFICATIONS izni gereklidir.
  /// Android 12+ (API 31+) için SCHEDULE_EXACT_ALARM izni gereklidir.
  ///
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
        debugPrint('SCHEDULE_EXACT_ALARM izni verilmemiş, isteniyor...');
        final result = await Permission.scheduleExactAlarm.request();

        // Bu izin kullanıcı tarafından ayarlardan verilmeli
        // Request sonucu her zaman denied dönebilir, bu normal
        debugPrint('SCHEDULE_EXACT_ALARM izni durumu: $result');

        // Alarm izni olmasa bile bildirimleri zamanlamayı deneyeceğiz
        // Bu yüzden false dönmüyoruz
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

  /// iOS için bildirim izinlerini kontrol eder ve ister
  ///
  /// iOS'ta bildirim izni alert, badge ve sound yetkilerini içerir.
  ///
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
  ///
  /// Bu metod sadece mevcut izin durumunu kontrol eder, kullanıcıdan izin istemez.
  ///
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
