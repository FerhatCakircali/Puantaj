import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

// Bildirim tıklama olayını dinlemek için global değişken
final StreamController<String> notificationClickStream =
    StreamController<String>.broadcast();

// Arka planda bildirim alındığında çalışacak top-level fonksiyon
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('🔥 NOTIFICATION TAP BACKGROUND: ${notificationResponse.payload}');

  // Bildirim ID'sini al ve kapat
  int notificationId = notificationResponse.id ?? 0;
  FlutterLocalNotificationsPlugin().cancel(id: notificationId);

  // Payload'ı işle
  if (notificationResponse.payload != null) {
    processNotificationPayloadStatic(notificationResponse.payload!);
  }
}

// Statik payload işleme metodu (arka plan işlemleri için)
@pragma('vm:entry-point')
Future<void> processNotificationPayloadStatic(String payload) async {
  try {
    debugPrint('🔄 Statik bildirim payload işleniyor: $payload');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_notification_payload', payload);
    await prefs.setBool('launched_from_notification', true);
    await prefs.setBool('notification_needs_handling', true);

    debugPrint('✅ Statik bildirim payload işlendi');
  } catch (e) {
    debugPrint('❌ Statik bildirim payload işleme hatası: $e');
  }
}

/// Bildirim yardımcı fonksiyonları
class NotificationHelpers {
  /// Timezone dönüşüm helper'ı
  static tz.TZDateTime toTZDateTime(DateTime dateTime) {
    try {
      return tz.TZDateTime.from(dateTime, tz.getLocation('Europe/Istanbul'));
    } catch (e) {
      debugPrint('⚠️ Timezone dönüşümü başarısız, UTC kullanılıyor: $e');
      return tz.TZDateTime.from(dateTime, tz.UTC);
    }
  }

  /// Şu anki zamanı TZDateTime olarak döndürür
  static tz.TZDateTime nowTZ() {
    return tz.TZDateTime.now(tz.local);
  }

  /// Belirli bir saat ve dakika için bugünün TZDateTime'ını oluşturur
  static tz.TZDateTime todayAt(int hour, int minute) {
    final now = nowTZ();
    return tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  }

  /// Çıkış yapıldığında tüm bildirimleri temizle
  static Future<void> clearAllNotificationsOnLogout(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    try {
      await plugin.cancelAll();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('launched_from_notification', false);
      await prefs.remove('last_notification_payload');
      await prefs.setBool('notification_needs_handling', false);

      // Bildirim ayarlarını temizle
      final keys = prefs
          .getKeys()
          .where(
            (key) =>
                key.startsWith('notification_sent_') ||
                key.startsWith('launched_from_notification') ||
                key.startsWith('notification_needs_handling') ||
                key.startsWith('last_notification_payload'),
          )
          .toList();

      for (final key in keys) {
        await prefs.remove(key);
      }

      debugPrint('✅ Çıkış: Tüm bildirimler ve durumlar temizlendi');
    } catch (e) {
      debugPrint('❌ Çıkış bildirim temizleme hatası: $e');
    }
  }

  /// Bekleyen bildirim bilgisini al (eski sistem uyumluluğu için)
  static Future<dynamic> getPendingNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final type = prefs.getString('pending_notification_type');
      if (type == null) return null;

      final reminderId = prefs.getInt('pending_notification_reminder_id');
      return {'type': type, 'reminderId': reminderId};
    } catch (e) {
      debugPrint('getPendingNotification hatası: $e');
      return null;
    }
  }

  /// Bekleyen bildirim bilgisini temizle (eski sistem uyumluluğu için)
  static Future<void> clearPendingNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_notification_type');
      await prefs.remove('pending_notification_reminder_id');
      debugPrint('Bekleyen bildirim temizlendi');
    } catch (e) {
      debugPrint('clearPendingNotification hatası: $e');
    }
  }
}
