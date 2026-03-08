import 'package:flutter/foundation.dart';
import '../../../../../../models/employee_reminder.dart';
import '../../../../services/employee_reminder_service.dart';

/// Hatırlatıcı yükleme ve silme işlemlerini yöneten sınıf
class ReminderLoader {
  final EmployeeReminderService _reminderService = EmployeeReminderService();

  /// Hatırlatıcıları yükler
  Future<List<EmployeeReminder>> loadReminders() async {
    try {
      return await _reminderService.getEmployeeReminders();
    } catch (e) {
      debugPrint('Hatırlatıcılar yüklenirken hata: $e');
      rethrow;
    }
  }

  /// Hatırlatıcıyı siler
  Future<bool> deleteReminder(int reminderId) async {
    try {
      return await _reminderService.deleteEmployeeReminderWithNotification(
        reminderId,
      );
    } catch (e) {
      debugPrint('Hatırlatıcı silinirken hata: $e');
      return false;
    }
  }

  /// Pending delete ID'lerini filtreler
  static List<EmployeeReminder> filterPendingDeletes(
    List<EmployeeReminder> reminders,
    Set<int> pendingDeleteIds,
  ) {
    return reminders
        .where((r) => r.id == null || !pendingDeleteIds.contains(r.id))
        .toList();
  }
}
