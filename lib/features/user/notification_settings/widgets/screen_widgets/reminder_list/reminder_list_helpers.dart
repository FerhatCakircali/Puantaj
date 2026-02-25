import 'package:flutter/material.dart';

import '../../../../../../models/employee_reminder.dart';

/// Helper fonksiyonlar - ReminderListView
class ReminderListHelpers {
  /// Hatırlatıcı durumunu hesaplar
  static ReminderStatus calculateStatus(EmployeeReminder reminder) {
    final now = DateTime.now();
    final isToday =
        reminder.reminderDate.day == now.day &&
        reminder.reminderDate.month == now.month &&
        reminder.reminderDate.year == now.year;
    final isPast = reminder.reminderDate.isBefore(now);
    final isCompleted = reminder.isCompleted;

    if (isCompleted) {
      return ReminderStatus.completed;
    } else if (isToday) {
      return ReminderStatus.today;
    } else if (isPast) {
      return ReminderStatus.past;
    } else {
      return ReminderStatus.pending;
    }
  }

  /// Durum bilgilerini döndürür
  static ReminderStatusInfo getStatusInfo(
    ReminderStatus status,
    ColorScheme colorScheme,
  ) {
    switch (status) {
      case ReminderStatus.completed:
        return ReminderStatusInfo(
          color: Colors.green,
          icon: Icons.check_circle,
          text: 'Tamamlandı',
        );
      case ReminderStatus.today:
        return ReminderStatusInfo(
          color: Colors.orange,
          icon: Icons.today,
          text: 'Bugün',
        );
      case ReminderStatus.past:
        return ReminderStatusInfo(
          color: Colors.red,
          icon: Icons.warning,
          text: 'Geçmiş',
        );
      case ReminderStatus.pending:
        return ReminderStatusInfo(
          color: colorScheme.primary,
          icon: Icons.notifications_active,
          text: 'Bekliyor',
        );
    }
  }
}

/// Hatırlatıcı durumu enum
enum ReminderStatus { completed, today, past, pending }

/// Durum bilgileri sınıfı
class ReminderStatusInfo {
  final Color color;
  final IconData icon;
  final String text;

  ReminderStatusInfo({
    required this.color,
    required this.icon,
    required this.text,
  });
}
