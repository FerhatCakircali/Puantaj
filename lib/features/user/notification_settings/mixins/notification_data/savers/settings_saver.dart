import 'package:flutter/foundation.dart';
import '../../../../../../models/notification_settings.dart';
import '../../../../../../services/attendance_check.dart';
import '../../../../../../services/notification_service.dart';

/// Bildirim ayarları kaydetme işlemlerini yöneten sınıf
class SettingsSaver {
  final NotificationService _notificationService = NotificationService();

  /// Bildirim ayarlarını kaydeder
  Future<bool> saveSettings({
    required NotificationSettings? currentSettings,
    required bool isEnabled,
    required bool autoApproveTrusted,
    required bool attendanceRequestsEnabled,
    required String selectedTime,
  }) async {
    try {
      debugPrint('Ayarlar kaydediliyor...');

      final userId = await _notificationService.getCurrentUserId();
      debugPrint('User ID: $userId');

      if (userId == null) {
        debugPrint('User ID null');
        return false;
      }

      final settingsToSave =
          currentSettings ??
          NotificationSettings(
            userId: userId,
            time: selectedTime,
            enabled: isEnabled,
            autoApproveTrusted: autoApproveTrusted,
            attendanceRequestsEnabled: attendanceRequestsEnabled,
            lastUpdated: DateTime.now(),
          );

      final updatedSettings = NotificationSettings(
        id: settingsToSave.id,
        userId: userId,
        time: selectedTime,
        enabled: isEnabled,
        autoApproveTrusted: autoApproveTrusted,
        attendanceRequestsEnabled: attendanceRequestsEnabled,
        lastUpdated: DateTime.now(),
      );

      debugPrint(
        'Kaydedilecek ayarlar: enabled=$isEnabled, time=$selectedTime',
      );

      final success = await _notificationService.updateNotificationSettings(
        updatedSettings,
      );

      debugPrint('Kaydetme sonucu: $success');
      return success;
    } catch (e) {
      debugPrint('Ayarlar kaydedilirken hata: $e');
      return false;
    }
  }

  /// Kaydetme sonrası mesajı oluşturur
  Future<String> getSaveSuccessMessage({
    required bool isEnabled,
    required String selectedTime,
  }) async {
    final hasAttendanceToday = await _notificationService
        .hasAttendanceEntryForToday();
    final attendanceDoneLocally = await AttendanceCheck.isTodayAttendanceDone();

    if (hasAttendanceToday || attendanceDoneLocally) {
      return 'Bildirim ayarları kaydedildi. Bugün için yevmiye girişi zaten yapılmış.';
    } else if (isEnabled) {
      final now = DateTime.now();
      final timeParts = selectedTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledTime.isBefore(now)) {
        return 'Bildirim ayarları kaydedildi. Belirtilen saat geçtiği için bildirim yarın etkin olacak.';
      } else {
        return 'Bildirim ayarları kaydedildi. Bildirim bugün $selectedTime saatinde gönderilecek.';
      }
    } else {
      return 'Bildirim ayarları kaydedildi. Bildirimler devre dışı bırakıldı.';
    }
  }
}
