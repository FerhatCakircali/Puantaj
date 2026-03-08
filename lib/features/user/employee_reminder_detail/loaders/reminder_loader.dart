import 'package:flutter/foundation.dart';
import '../../../../models/employee_reminder.dart';
import '../../services/employee_reminder_service.dart';
import '../utils/reminder_id_resolver.dart';

/// Hatırlatıcı yükleme sınıfı
class ReminderLoader {
  final EmployeeReminderService _reminderService = EmployeeReminderService();

  /// Hatırlatıcıyı yükler ve tamamlandı olarak işaretler
  Future<EmployeeReminder?> load(int? routerReminderId) async {
    try {
      // ID'yi çözümle
      final reminderId = await ReminderIdResolver.resolve(routerReminderId);

      if (reminderId == null) {
        debugPrint('Hiçbir kaynaktan reminderId alınamadı');
        return null;
      }

      debugPrint('Hatırlatıcı yükleniyor (ID: $reminderId)');

      // Tüm hatırlatıcıları al
      final reminders = await _reminderService.getEmployeeReminders(
        includeCompleted: true,
      );

      // ID'ye göre hatırlatıcıyı bul
      final reminder = reminders.firstWhere(
        (r) => r.id == reminderId,
        orElse: () => throw Exception('Hatırlatıcı bulunamadı'),
      );

      debugPrint('Hatırlatıcı yüklendi: ${reminder.workerName}');

      // Hatırlatıcıyı tamamlandı olarak işaretle
      await _reminderService.markReminderAsCompletedWithNotification(
        reminderId,
      );

      debugPrint('Hatırlatıcı tamamlandı olarak işaretlendi');

      return reminder;
    } catch (e, stackTrace) {
      debugPrint('Hatırlatıcı yükleme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
