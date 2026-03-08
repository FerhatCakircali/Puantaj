import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/notification_service.dart';

/// Hatırlatıcı ID çözümleme sınıfı
///
/// Farklı kaynaklardan hatırlatıcı ID'sini çözümler:
/// 1. Router parametresi (öncelik 1)
/// 2. NotificationService (öncelik 2)
/// 3. SharedPreferences (öncelik 3)
class ReminderIdResolver {
  /// Hatırlatıcı ID'sini çözümler
  static Future<int?> resolve(int? routerReminderId) async {
    // Öncelik 1: Router'dan gelen reminderId
    if (routerReminderId != null) {
      debugPrint('Router\'dan reminderId alındı: $routerReminderId');
      return routerReminderId;
    }

    debugPrint(
      'Router\'dan reminderId gelmedi, fallback mekanizmaları deneniyor',
    );

    // Öncelik 2: NotificationService'ten kontrol et
    final notificationId = await _resolveFromNotificationService();
    if (notificationId != null) {
      return notificationId;
    }

    // Öncelik 3: SharedPreferences'tan kontrol et
    return await _resolveFromSharedPreferences();
  }

  /// NotificationService'ten ID çözümler
  static Future<int?> _resolveFromNotificationService() async {
    try {
      final notificationService = NotificationService();
      final notification = await notificationService.getPendingNotification();

      if (notification != null && notification.isEmployeeReminder) {
        final reminderId = notification.reminderId;
        debugPrint('NotificationService\'ten reminderId alındı: $reminderId');
        return reminderId;
      }
    } catch (e) {
      debugPrint('NotificationService fallback hatası: $e');
    }
    return null;
  }

  /// SharedPreferences'tan ID çözümler
  static Future<int?> _resolveFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reminderId = prefs.getInt('active_employee_reminder_id');

      if (reminderId != null) {
        debugPrint('SharedPreferences\'tan reminderId alındı: $reminderId');
      }

      return reminderId;
    } catch (e) {
      debugPrint('SharedPreferences fallback hatası: $e');
    }
    return null;
  }
}
