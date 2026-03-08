import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/notification_service.dart';
import '../../services/employee_reminder_service.dart';

/// Hatırlatıcı silme işlemlerini yöneten sınıf
class ReminderDeleteHandler {
  final EmployeeReminderService _reminderService = EmployeeReminderService();

  /// Hatırlatıcıyı siler ve bildirim durumunu temizler
  Future<bool> delete(int reminderId) async {
    try {
      debugPrint('Hatırlatıcı siliniyor (ID: $reminderId)');

      final success = await _reminderService
          .deleteEmployeeReminderWithNotification(reminderId);

      if (success) {
        debugPrint('Hatırlatıcı başarıyla silindi');
        await _clearNotificationState();
        return true;
      } else {
        debugPrint('Silme işlemi başarısız');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Silme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Bildirim durumunu temizler
  Future<void> _clearNotificationState() async {
    try {
      final notificationService = NotificationService();
      await notificationService.clearPendingNotification();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_employee_reminder_id');

      debugPrint('Bildirim durumu temizlendi');
    } catch (e) {
      debugPrint('Bildirim temizleme hatası (göz ardı edildi): $e');
    }
  }
}
