import 'package:flutter/material.dart';
import '../../../../../models/notification_settings.dart';
import '../../../../../services/notification_service.dart';

/// Bildirim ayarlarını kaydeden helper sınıfı
class NotificationSettingsSaver {
  final NotificationService notificationService;

  NotificationSettingsSaver(this.notificationService);

  /// Otomatik onay ayarlarını kaydeder
  Future<bool> saveAutoApproveSettings({
    required NotificationSettings? currentSettings,
    required TimeOfDay selectedTime,
    required bool isEnabled,
    required bool autoApproveTrusted,
    required bool attendanceRequestsEnabled,
  }) async {
    try {
      final userId = await notificationService.getCurrentUserId();
      if (userId == null) {
        return false;
      }

      final settingsToSave =
          currentSettings ??
          NotificationSettings(
            userId: userId,
            time: _formatTime(selectedTime),
            enabled: isEnabled,
            autoApproveTrusted: autoApproveTrusted,
            attendanceRequestsEnabled: attendanceRequestsEnabled,
            lastUpdated: DateTime.now(),
          );

      final updatedSettings = NotificationSettings(
        id: settingsToSave.id,
        userId: userId,
        time: _formatTime(selectedTime),
        enabled: isEnabled,
        autoApproveTrusted: autoApproveTrusted,
        attendanceRequestsEnabled: attendanceRequestsEnabled,
        lastUpdated: DateTime.now(),
      );

      return await notificationService.updateNotificationSettings(
        updatedSettings,
      );
    } catch (e) {
      debugPrint('Ayar kaydetme hatası: $e');
      return false;
    }
  }

  /// Yevmiye talep ayarlarını kaydeder
  /// FCM ile anında bildirim gönderilir
  Future<bool> saveAttendanceRequestsSettings({
    required NotificationSettings? currentSettings,
    required TimeOfDay selectedTime,
    required bool isEnabled,
    required bool autoApproveTrusted,
    required bool attendanceRequestsEnabled,
  }) async {
    try {
      final userId = await notificationService.getCurrentUserId();
      if (userId == null) {
        return false;
      }

      final settingsToSave =
          currentSettings ??
          NotificationSettings(
            userId: userId,
            time: _formatTime(selectedTime),
            enabled: isEnabled,
            autoApproveTrusted: autoApproveTrusted,
            attendanceRequestsEnabled: attendanceRequestsEnabled,
            lastUpdated: DateTime.now(),
          );

      final updatedSettings = NotificationSettings(
        id: settingsToSave.id,
        userId: userId,
        time: _formatTime(selectedTime),
        enabled: isEnabled,
        autoApproveTrusted: autoApproveTrusted,
        attendanceRequestsEnabled: attendanceRequestsEnabled,
        lastUpdated: DateTime.now(),
      );

      final success = await notificationService.updateNotificationSettings(
        updatedSettings,
      );

      if (success) {
        debugPrint(
          attendanceRequestsEnabled
              ? '✅ Yevmiye talep bildirimleri FCM ile aktif'
              : '🛑 Yevmiye talep bildirimleri kapatıldı',
        );
      }

      return success;
    } catch (e) {
      debugPrint('Ayar kaydetme hatası: $e');
      return false;
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
