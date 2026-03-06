import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/notification_service.dart';

/// Çalışan bildirim servisi
/// SQL tabloları:
/// - notifications: Bildirimler
/// - notification_settings_workers: Hatırlatıcı ayarları
class WorkerNotificationService {
  SupabaseClient get supabase => Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  /// Okunmamış bildirimleri getir
    /// SQL: SELECT * FROM notifications
  /// WHERE recipient_id = ? AND recipient_type = 'worker' AND is_read = FALSE
  Future<List<Map<String, dynamic>>> getUnreadNotifications(
    int workerId,
  ) async {
    try {
      final response = await supabase
          .from('notifications')
          .select()
          .eq('recipient_id', workerId)
          .eq('recipient_type', 'worker')
          .eq('is_read', false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getUnreadNotifications hata: $e');
      return [];
    }
  }

  /// Tüm bildirimleri getir
  Future<List<Map<String, dynamic>>> getAllNotifications(int workerId) async {
    try {
      final response = await supabase
          .from('notifications')
          .select()
          .eq('recipient_id', workerId)
          .eq('recipient_type', 'worker')
          .order('created_at', ascending: false)
          .limit(50);

      final notifications = List<Map<String, dynamic>>.from(response);

      // Debug: is_read durumlarını logla
      debugPrint('Bildirimler yüklendi: ${notifications.length} adet');
      for (var notif in notifications) {
        debugPrint(
          '  - ${notif['title']}: is_read=${notif['is_read']} (ID: ${notif['id']})',
        );
      }

      return notifications;
    } catch (e) {
      debugPrint('getAllNotifications hata: $e');
      return [];
    }
  }

  /// Bildirimi okundu işaretle
    /// SQL: UPDATE notifications SET is_read = TRUE WHERE id = ?
  Future<bool> markAsRead(int notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      debugPrint('Bildirim okundu işaretlendi');
      return true;
    } catch (e) {
      debugPrint('markAsRead hata: $e');
      return false;
    }
  }

  /// Tüm bildirimleri okundu işaretle
  Future<bool> markAllAsRead(int workerId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('recipient_id', workerId)
          .eq('recipient_type', 'worker')
          .eq('is_read', false);

      debugPrint('Tüm bildirimler okundu işaretlendi');
      return true;
    } catch (e) {
      debugPrint('markAllAsRead hata: $e');
      return false;
    }
  }

  /// Hatırlatıcı ayarlarını getir
    /// SQL: SELECT * FROM notification_settings_workers WHERE worker_id = ?
  Future<Map<String, dynamic>?> getReminderSettings(int workerId) async {
    try {
      final response = await supabase
          .from('notification_settings_workers')
          .select()
          .eq('worker_id', workerId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('getReminderSettings hata: $e');
      return null;
    }
  }

  /// Hatırlatıcı ayarlarını kaydet/güncelle (UPSERT)
    /// SQL: INSERT INTO notification_settings_workers (worker_id, time, enabled)
  /// VALUES (?, ?, ?)
  /// ON CONFLICT (worker_id)
  /// DO UPDATE SET time = EXCLUDED.time, enabled = EXCLUDED.enabled
  Future<bool> saveReminderSettings({
    required int workerId,
    required String time,
    required bool enabled,
  }) async {
    try {
      await supabase.from('notification_settings_workers').upsert({
        'worker_id': workerId,
        'time': time,
        'enabled': enabled,
        'last_updated': DateTime.now().toIso8601String(),
      }, onConflict: 'worker_id');

      debugPrint('Hatırlatıcı ayarları kaydedildi');
      return true;
    } catch (e) {
      debugPrint('saveReminderSettings hata: $e');
      return false;
    }
  }

  /// Hatırlatıcı ayarlarını sil
    /// SQL: DELETE FROM notification_settings_workers WHERE worker_id = ?
  Future<bool> deleteReminderSettings(int workerId) async {
    try {
      await supabase
          .from('notification_settings_workers')
          .delete()
          .eq('worker_id', workerId);

      debugPrint('Hatırlatıcı ayarları silindi');
      return true;
    } catch (e) {
      debugPrint('deleteReminderSettings hata: $e');
      return false;
    }
  }

  /// Çalışan için yevmiye hatırlatıcısını zamanla
    /// Kullanıcı panelindeki sistemi kullanarak çalışan için bildirim zamanlar.
  /// NotificationPayload objesi ile JSON payload oluşturur.
  Future<void> scheduleWorkerAttendanceReminder({
    required int workerId,
    required String workerName,
    required TimeOfDay time,
  }) async {
    try {
      debugPrint('ÇALIŞAN HATIRLATıCıSı ZAMANLANIYOR');
      debugPrint('Worker ID: $workerId');
      debugPrint('İsim: $workerName');
      debugPrint('Saat: ${time.hour}:${time.minute}');
      debugPrint('Bildirim ID: ${1000 + workerId}');

      // Mevcut NotificationService'i kullan
      // KULLANICI PANELİ İLE AYNI MANTIK: NotificationPayload JSON objesi payload olarak kaydedilecek
      await _notificationService.scheduleAttendanceReminder(
        userId: workerId,
        username: 'worker_$workerId',
        fullName: workerName,
        time: time,
      );

      debugPrint('ÇALIŞAN HATIRLATıCıSı ZAMANLANDIIII');

      // Zamanlanmış bildirimleri kontrol et
      final pendingNotifications = await _notificationService
          .flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      debugPrint('Bekleyen bildirim sayısı: ${pendingNotifications.length}');
      for (var notif in pendingNotifications) {
        debugPrint(
          '  - ID: ${notif.id}, Başlık: ${notif.title}, Body: ${notif.body}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('ÇALIŞAN HATIRLATıCıSı HATA: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Çalışan için yevmiye hatırlatıcısını iptal et
    /// Zamanlanmış bildirimi iptal eder.
  /// Bildirim ID'si: 1000 + workerId
  Future<void> cancelWorkerAttendanceReminder(int workerId) async {
    try {
      debugPrint('🚫 Çalışan hatırlatıcısı iptal ediliyor...');
      debugPrint('Worker ID: $workerId');

      // Worker ID bazlı benzersiz ID kullan (1000 + workerId)
      final notificationId = 1000 + workerId;
      await _notificationService.cancelNotification(notificationId);

      debugPrint('Bildirim iptal edildi: $notificationId');
      debugPrint('Çalışan hatırlatıcısı iptal edildi');
    } catch (e) {
      debugPrint('Çalışan hatırlatıcısı iptal edilirken hata: $e');
    }
  }

  /// Bugün için yevmiye girişi yapılmış mı kontrol et
    /// Bildirim gösterilmeden önce kontrol için kullanılır
  Future<bool> hasAttendanceToday(int workerId) async {
    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Attendance tablosunda bugün için kayıt var mı?
      final attendanceResponse = await supabase
          .from('attendance')
          .select('id')
          .eq('worker_id', workerId)
          .eq('date', todayStr)
          .maybeSingle();

      if (attendanceResponse != null) {
        debugPrint('Bugün için attendance kaydı var');
        return true;
      }

      // Attendance_requests tablosunda bugün için kayıt var mı?
      final requestResponse = await supabase
          .from('attendance_requests')
          .select('id')
          .eq('worker_id', workerId)
          .eq('date', todayStr)
          .maybeSingle();

      if (requestResponse != null) {
        debugPrint('Bugün için attendance_request kaydı var');
        return true;
      }

      debugPrint('Bugün için yevmiye kaydı yok');
      return false;
    } catch (e) {
      debugPrint('hasAttendanceToday hata: $e');
      return false;
    }
  }
}
