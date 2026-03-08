import 'package:flutter/foundation.dart';
import '../../../../../../models/notification_settings.dart';
import '../../../../../../services/notification_service.dart';

/// Bildirim ayarları yükleme işlemlerini yöneten sınıf
class SettingsLoader {
  final NotificationService _notificationService = NotificationService();

  /// Bildirim ayarlarını yükler
  Future<NotificationSettings?> loadSettings() async {
    try {
      debugPrint('Bildirim ayarları yükleniyor...');

      final userId = await _notificationService.getCurrentUserId();
      debugPrint('User ID: $userId');

      if (userId == null) {
        debugPrint('User ID null');
        return null;
      }

      final settings = await _notificationService.getNotificationSettings();
      debugPrint('Veritabanından gelen ayarlar: $settings');
      debugPrint('enabled: ${settings?.enabled}, time: ${settings?.time}');

      return settings;
    } catch (e) {
      debugPrint('Ayarlar yüklenirken hata: $e');
      rethrow;
    }
  }

  /// Varsayılan ayarları döndürür
  static Map<String, dynamic> getDefaultSettings() {
    return {
      'isEnabled': false,
      'autoApproveTrusted': false,
      'attendanceRequestsEnabled': true,
      'selectedTime': '18:00',
    };
  }
}
