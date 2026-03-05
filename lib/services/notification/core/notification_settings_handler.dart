import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/app_globals.dart';
import '../../../models/notification_settings.dart';
import '../../attendance_check.dart';
import '../../auth_service.dart';
import '../mixins/notification_scheduling_mixin.dart';

/// Bildirim ayarları yönetimi
class NotificationSettingsHandler {
  final FlutterLocalNotificationsPlugin plugin;
  final AuthService authService;
  final NotificationSchedulingMixin schedulingMixin;

  NotificationSettingsHandler({
    required this.plugin,
    required this.authService,
    required this.schedulingMixin,
  });

  /// Uygulama açıldığında bildirimleri kontrol et ve yeniden zamanla
  Future<void> checkAndRescheduleNotifications() async {
    try {
      debugPrint('Bildirim ayarları kontrol ediliyor...');

      final isDoneLocally = await AttendanceCheck.isTodayAttendanceDone();
      if (isDoneLocally) {
        debugPrint(
          'Bugün için yevmiye girişi bulundu, bildirimler temizleniyor',
        );
        await plugin.cancelAll();

        final now = DateTime.now();
        String todayKey =
            'notification_sent_${now.year}_${now.month}_${now.day}';
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool(todayKey, true);
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool launchedFromNotification =
          prefs.getBool('launched_from_notification') ?? false;

      if (launchedFromNotification) {
        debugPrint(
          'Uygulama bildirimden başlatılmış, bildirimler temizleniyor',
        );
        await plugin.cancelAll();

        final now = DateTime.now();
        String todayKey =
            'notification_sent_${now.year}_${now.month}_${now.day}';
        await prefs.setBool(todayKey, true);
        return;
      }

      final settings = await getNotificationSettings();

      if (settings == null) {
        debugPrint('Bildirim ayarları bulunamadı, bildirimler iptal ediliyor');
        await plugin.cancelAll();
      } else if (settings.enabled) {
        debugPrint('Bildirimler etkin, kontrol ediliyor...');

        final pendingNotifications = await plugin.pendingNotificationRequests();

        if (pendingNotifications.isEmpty) {
          debugPrint('Zamanlanmış bildirim yok, yeniden zamanlanıyor...');

          final user = await authService.currentUser;
          if (user != null) {
            final userId = user['id'] as int;
            final username = user['username'] as String;
            final firstName = user['first_name'] as String? ?? '';
            final lastName = user['last_name'] as String? ?? '';
            final fullName = '$firstName $lastName'.trim();

            final timeParts = settings.time.split(':');
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);

            await schedulingMixin.scheduleAttendanceReminder(
              userId: userId,
              username: username,
              fullName: fullName,
              time: TimeOfDay(hour: hour, minute: minute),
            );
          }
        }
      } else {
        debugPrint('Bildirimler devre dışı, yevmiye bildirimi iptal ediliyor');
        await plugin.cancel(1);
      }
    } catch (e, stack) {
      debugPrint('Bildirimler kontrol edilirken hata: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  /// Bugün için yevmiye kaydı var mı kontrol eder
  Future<bool> hasAttendanceEntryForToday() async {
    try {
      final userId = await authService.getUserId();
      if (userId == null) return false;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final List<dynamic> res = await supabase
          .from('attendance')
          .select('id')
          .eq('user_id', userId)
          .gte('date', startOfDay.toIso8601String())
          .lt('date', endOfDay.toIso8601String());

      return res.isNotEmpty;
    } catch (e) {
      debugPrint('hasAttendanceEntryForToday hatası: $e');
      return false;
    }
  }

  /// Bildirim ayarlarını veritabanından al
  Future<NotificationSettings?> getNotificationSettings() async {
    final userId = await authService.getUserId();
    if (userId == null) return null;

    try {
      final results = await supabase
          .from('notification_settings')
          .select()
          .eq('user_id', userId)
          .order('id', ascending: false);

      if (results.isNotEmpty) {
        return NotificationSettings.fromMap(results.first);
      }
      return null;
    } catch (e) {
      debugPrint('getNotificationSettings hatası: $e');
      return null;
    }
  }

  /// Bildirim ayarlarını güncelle
  Future<bool> updateNotificationSettings(NotificationSettings settings) async {
    try {
      final savedSettings = await _saveNotificationSettings(settings);
      if (savedSettings == null) return false;

      final hasAttendanceToday = await hasAttendanceEntryForToday();
      final localAttendanceDone = await AttendanceCheck.isTodayAttendanceDone();

      if (hasAttendanceToday || localAttendanceDone) {
        await plugin.cancelAll();
        debugPrint(
          'Bugün için yevmiye girişi yapıldığından bildirimler iptal edildi',
        );
        return true;
      }

      if (settings.enabled) {
        final user = await authService.currentUser;
        if (user != null) {
          final userId = user['id'] as int;
          final username = user['username'] as String;
          final firstName = user['first_name'] as String? ?? '';
          final lastName = user['last_name'] as String? ?? '';
          final fullName = '$firstName $lastName'.trim();

          final timeParts = settings.time.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);

          await schedulingMixin.scheduleAttendanceReminder(
            userId: userId,
            username: username,
            fullName: fullName,
            time: TimeOfDay(hour: hour, minute: minute),
          );
        }
      } else {
        debugPrint('Bildirimler devre dışı bırakıldı');
      }

      return true;
    } catch (e, stack) {
      debugPrint('updateNotificationSettings hatası: $e');
      debugPrint('Stack trace: $stack');
      return false;
    }
  }

  /// Bildirim ayarlarını veritabanına kaydeder
  Future<NotificationSettings?> _saveNotificationSettings(
    NotificationSettings settings,
  ) async {
    try {
      debugPrint('💾 [DB] Veritabanına kaydediliyor...');
      debugPrint('💾 [DB] settings.enabled: ${settings.enabled}');
      debugPrint('💾 [DB] settings.toMap(): ${settings.toMap()}');

      await supabase
          .from('notification_settings')
          .delete()
          .eq('user_id', settings.userId);

      debugPrint('💾 [DB] Eski kayıt silindi');

      final response = await supabase
          .from('notification_settings')
          .insert(settings.toMap())
          .select();

      debugPrint('💾 [DB] Insert response: $response');

      if (response.isEmpty) {
        debugPrint('❌ [DB] Response boş!');
        return null;
      }

      final savedSettings = NotificationSettings.fromMap(response.first);
      debugPrint(
        '💾 [DB] Kaydedilen ayarlar: enabled=${savedSettings.enabled}',
      );

      return savedSettings;
    } catch (e) {
      debugPrint('❌ [DB] _saveNotificationSettings hatası: $e');
      return null;
    }
  }

  /// Çıkış yapıldığında tüm bildirimleri temizle
  Future<void> clearAllNotificationsOnLogout() async {
    try {
      await plugin.cancelAll();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('launched_from_notification', false);
      await prefs.remove('last_notification_payload');
      await prefs.setBool('notification_needs_handling', false);

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
}
