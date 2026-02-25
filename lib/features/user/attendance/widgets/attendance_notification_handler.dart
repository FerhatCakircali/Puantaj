import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../models/employee.dart';
import '../../../../services/attendance_check.dart';
import '../../../../services/notification_service.dart' as old_ns;

/// Yevmiye bildirim işlemleri handler'ı
class AttendanceNotificationHandler {
  /// Yevmiye bildirimi varsa temizle
  static Future<void> checkAndClearAttendanceNotification() async {
    try {
      final notificationService = old_ns.NotificationService();
      final notification = await notificationService.getPendingNotification();
      if (notification != null && notification.isAttendanceReminder) {
        debugPrint('📋 AttendanceScreen: Yevmiye bildirimi temizleniyor');
        await notificationService.clearPendingNotification();
        debugPrint('✅ AttendanceScreen: Yevmiye bildirimi temizlendi');
      }
    } catch (e) {
      debugPrint('❌ AttendanceScreen: Bildirim temizleme hatası: $e');
    }
  }

  /// Bugün için yevmiye yapıldı olarak işaretle
  static Future<void> markTodayAttendanceDone() async {
    final today = DateTime.now();

    try {
      await AttendanceCheck.markAttendanceDone();
      debugPrint('AttendanceCheck.markAttendanceDone() başarıyla çalıştı');

      final notificationServiceV2 = old_ns.NotificationService();
      await notificationServiceV2.cancelNotification(1);
      debugPrint('Yeni bildirim servisi ile bildirim iptal edildi');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String todayKey =
          'notification_sent_${today.year}_${today.month}_${today.day}';
      await prefs.setBool(todayKey, true);
      debugPrint(
        'SharedPreferences üzerinde $todayKey = true olarak ayarlandı',
      );

      final user = await old_ns.NotificationService().authService.currentUser;
      if (user != null) {
        final userId = user['id'] as int;
        final userAttendanceKey = 'attendance_date_user_$userId';
        await prefs.setString(userAttendanceKey, today.toIso8601String());
        debugPrint(
          'Kullanıcıya özel yevmiye durumu güncellendi: $userAttendanceKey',
        );
      }

      debugPrint('Bildirim durumu başarıyla güncellendi');
    } catch (e) {
      debugPrint('Bildirim durumu güncellenirken hata: $e');
      rethrow;
    }
  }

  /// Yevmiye yapmamış çalışanlara hatırlatma gönder
  static Future<void> sendRemindersToWorkers(
    BuildContext context,
    List<Employee> workersWithoutAttendance,
  ) async {
    try {
      final notificationService = old_ns.NotificationService();
      final currentUser = await notificationService.authService.currentUser;

      if (currentUser == null) {
        throw Exception('Kullanıcı bilgisi alınamadı');
      }

      final managerId = currentUser['id'] as int;

      final now = DateTime.now();
      final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

      for (final worker in workersWithoutAttendance) {
        // 1. Local bildirim gönder
        await notificationService.scheduleAttendanceReminder(
          userId: worker.id,
          username: worker.name,
          fullName: worker.name,
          time: currentTime,
        );

        // 2. Veritabanına bildirim kaydı ekle
        try {
          await Supabase.instance.client.from('notifications').insert({
            'sender_id': managerId,
            'sender_type': 'user',
            'recipient_id': worker.id,
            'recipient_type': 'worker',
            'notification_type': 'attendance_reminder',
            'title': 'Yevmiye Girişi Hatırlatması',
            'message': 'Bugün için yevmiye girişi yapmanız gerekiyor.',
            'is_read': false,
            'scheduled_time': null,
          });
          debugPrint(
            '✅ Çalışan ${worker.name} için bildirim veritabanına kaydedildi',
          );
        } catch (e) {
          debugPrint(
            '❌ Çalışan ${worker.name} için bildirim kaydedilemedi: $e',
          );
        }
      }
    } catch (e) {
      debugPrint('Hatırlatma gönderme hatası: $e');
      rethrow;
    }
  }
}
