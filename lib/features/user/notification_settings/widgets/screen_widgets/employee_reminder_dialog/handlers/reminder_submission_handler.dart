import 'package:flutter/material.dart';
import '../../../../../../../models/worker.dart';
import '../../../../../../../models/employee_reminder.dart';
import '../../../../../services/employee_reminder_service.dart';

/// Hatırlatıcı kaydetme işlemlerini yöneten sınıf
class ReminderSubmissionHandler {
  final EmployeeReminderService _reminderService = EmployeeReminderService();

  /// Hatırlatıcıyı kaydeder ve sonucu döndürür
  Future<bool> saveReminder({
    required BuildContext context,
    required Worker worker,
    required DateTime selectedDate,
    required TimeOfDay selectedTime,
    required String message,
  }) async {
    if (message.trim().isEmpty) {
      _showSnackBar(context, 'Lütfen bir hatırlatıcı mesajı girin');
      return false;
    }

    try {
      final reminderDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      final reminder = EmployeeReminder(
        userId: worker.userId,
        workerId: worker.id!,
        workerName: worker.fullName,
        reminderDate: reminderDate,
        message: message.trim(),
      );

      final result = await _reminderService.addEmployeeReminderWithNotification(
        reminder,
      );

      if (!context.mounted) return false;

      if (result != null) {
        _showSnackBar(context, '${worker.fullName} için hatırlatıcı eklendi');
        return true;
      } else {
        _showSnackBar(context, 'Hatırlatıcı eklenirken bir hata oluştu');
        return false;
      }
    } catch (e) {
      if (!context.mounted) return false;
      _showSnackBar(context, 'Hatırlatıcı eklenirken bir hata oluştu');
      return false;
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
