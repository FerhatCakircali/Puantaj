import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Bildirim gösterme işlemlerini yönetir
class NotificationDisplayHelper {
  final FlutterLocalNotificationsPlugin plugin;

  NotificationDisplayHelper({required this.plugin});

  /// Timezone dönüşüm helper'ı
  tz.TZDateTime toTZDateTime(DateTime dateTime) {
    try {
      return tz.TZDateTime.from(dateTime, tz.getLocation('Europe/Istanbul'));
    } catch (e) {
      debugPrint('⚠️ Timezone dönüşümü başarısız, UTC kullanılıyor: $e');
      return tz.TZDateTime.from(dateTime, tz.UTC);
    }
  }

  /// Şu anki zamanı TZDateTime olarak döndürür
  tz.TZDateTime nowTZ() {
    return tz.TZDateTime.now(tz.local);
  }

  /// Belirli bir saat ve dakika için bugünün TZDateTime'ını oluşturur
  tz.TZDateTime todayAt(int hour, int minute) {
    final now = nowTZ();
    return tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  }

  /// Anlık bildirim gösterir
  ///
  /// Tüm Android cihazlar için optimize edilmiştir.
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      debugPrint('📢 Anlık bildirim gösteriliyor...');
      debugPrint('  ID: $id');
      debugPrint('  Başlık: $title');
      debugPrint('  Mesaj: $body');
      debugPrint('  Payload: $payload');

      const androidDetails = AndroidNotificationDetails(
        'attendance_channel',
        'Yevmiye Bildirimleri',
        channelDescription: 'Yevmiye girişi ve onay bildirimleri',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        enableLights: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await plugin.show(id, title, body, details, payload: payload);

      debugPrint('✅ Anlık bildirim gösterildi');
    } catch (e, stackTrace) {
      debugPrint('❌ Anlık bildirim gösterilemedi: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Belirli bir zamanda bildirim göster
  Future<void> scheduleNotificationAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      debugPrint('📅 Zamanlanmış bildirim ayarlanıyor...');
      debugPrint('  ID: $id');
      debugPrint('  Başlık: $title');
      debugPrint('  Mesaj: $body');
      debugPrint('  Zamanlanacak saat (Local): ${scheduledTime.toString()}');
      debugPrint('  Payload: $payload');

      final now = DateTime.now();
      if (scheduledTime.isBefore(now)) {
        debugPrint('⚠️⚠️⚠️ UYARI: Zamanlama GEÇMİŞTE!');
        debugPrint('  Şimdi: ${now.toString()}');
        debugPrint('  Zamanlanan: ${scheduledTime.toString()}');
        debugPrint(
          '  Fark: ${now.difference(scheduledTime).inSeconds} saniye önce',
        );
        scheduledTime = now.add(const Duration(seconds: 5));
        debugPrint('  Yeni zamanlama: ${scheduledTime.toString()}');
      }

      final pendingBefore = await plugin.pendingNotificationRequests();
      debugPrint(
        '📋 Zamanlamadan ÖNCE pending sayısı: ${pendingBefore.length}',
      );

      final existingWithSameId = pendingBefore
          .where((p) => p.id == id)
          .toList();
      if (existingWithSameId.isNotEmpty) {
        debugPrint(
          '⚠️ UYARI: Aynı ID ($id) ile zaten zamanlanmış bildirim var!',
        );
        debugPrint('  Mevcut: ${existingWithSameId.first.title}');
        debugPrint('  Yeni: $title');
        await plugin.cancel(id);
        debugPrint('  ✅ Eski bildirim iptal edildi');
      }

      const channelId = 'attendance_requests';

      const androidDetails = AndroidNotificationDetails(
        channelId,
        'Yevmiye Talepleri',
        channelDescription:
            'Çalışanlardan gelen yevmiye girişi onay bildirimleri',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        enableLights: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final tzScheduledTime = toTZDateTime(scheduledTime);

      debugPrint('  TZ Scheduled Time: ${tzScheduledTime.toString()}');
      debugPrint('  TZ Location: ${tzScheduledTime.location.name}');

      final tzNow = tz.TZDateTime.now(tz.getLocation('Europe/Istanbul'));
      if (tzScheduledTime.isBefore(tzNow)) {
        debugPrint('⚠️⚠️⚠️ UYARI: TZ Zamanlama GEÇMİŞTE!');
        debugPrint('  TZ Şimdi: ${tzNow.toString()}');
        debugPrint('  TZ Zamanlanan: ${tzScheduledTime.toString()}');
        debugPrint(
          '  Fark: ${tzNow.difference(tzScheduledTime).inSeconds} saniye önce',
        );
      }

      debugPrint('🔄 zonedSchedule çağrılıyor...');

      try {
        await plugin.cancel(id);
        debugPrint('  ✅ Eski bildirim iptal edildi (varsa)');
      } catch (e) {
        debugPrint('  ⚠️ Eski bildirim iptal hatası (devam ediliyor): $e');
      }

      await Future.delayed(const Duration(milliseconds: 100));

      await plugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      debugPrint('✅ Zamanlanmış bildirim ayarlandı');

      final pendingAfter = await plugin.pendingNotificationRequests();
      debugPrint(
        '📋 Zamanlandıktan SONRA pending sayısı: ${pendingAfter.length}',
      );
      debugPrint(
        '📊 Fark: ${pendingAfter.length - pendingBefore.length} bildirim eklendi',
      );

      final newNotification = pendingAfter.where((p) => p.id == id).toList();
      if (newNotification.isEmpty) {
        debugPrint('❌❌❌ HATA: Bildirim zamanlandı ama pending listesinde YOK!');
      } else {
        debugPrint('✅ Bildirim pending listesinde bulundu:');
        debugPrint('  - ID: ${newNotification.first.id}');
        debugPrint('  - Title: ${newNotification.first.title}');
        debugPrint('  - Body: ${newNotification.first.body}');
      }

      debugPrint('📋 Tüm zamanlanmış bildirimler:');
      for (final p in pendingAfter) {
        debugPrint('  - ID: ${p.id}, Title: ${p.title}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Zamanlanmış bildirim ayarlanamadı: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Belirli bir bildirimi iptal eder
  Future<void> cancelNotification(int? id) async {
    if (id == null) return;
    try {
      await plugin.cancel(id);
      debugPrint('Bildirim iptal edildi: $id');
    } catch (e) {
      debugPrint('Bildirim iptal edilirken hata: $e');
    }
  }
}
