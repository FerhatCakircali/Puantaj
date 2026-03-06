import '../../../models/employee_reminder.dart';
import 'employee_reminder/index.dart';
import '../../../services/notification_service.dart';
import '../../../services/auth_service.dart';
import 'package:flutter/material.dart';

/// Çalışan hatırlatıcıları servisi - Orchestrator
/// Bu servis, ReminderDataMixin ve ReminderLogicMixin'leri birleştirerek
/// çalışan hatırlatıcıları için tam bir yönetim çözümü sunar.
class EmployeeReminderService with ReminderDataMixin, ReminderLogicMixin {
  final NotificationService _notificationServiceV2 = NotificationService();
  // ignore: unused_field
  final AuthService _authService = AuthService();

  /// Hatırlatıcı ekle ve bildirim zamanla
  Future<EmployeeReminder?> addEmployeeReminderWithNotification(
    EmployeeReminder reminder,
  ) async {
    final newReminder = await addEmployeeReminder(reminder);
    if (newReminder != null) {
      await _scheduleReminderWithNewSystem(newReminder);
    }
    return newReminder;
  }

  /// Hatırlatıcıyı güncelle ve bildirim yönet
  Future<bool> updateEmployeeReminderWithNotification(
    EmployeeReminder reminder,
  ) async {
    final success = await updateEmployeeReminder(reminder);
    if (success) {
      if (!reminder.isCompleted) {
        await _scheduleReminderWithNewSystem(reminder);
      } else {
        await _cancelReminderWithNewSystem(reminder);
      }
    }
    return success;
  }

  /// Hatırlatıcıyı sil ve bildirim iptal et
  Future<bool> deleteEmployeeReminderWithNotification(int reminderId) async {
    final reminder = await getReminderById(reminderId);
    if (reminder != null) {
      await _cancelReminderWithNewSystem(reminder);
    }
    return await deleteEmployeeReminder(reminderId);
  }

  /// Hatırlatıcıyı tamamlandı olarak işaretle ve bildirim iptal et
  Future<bool> markReminderAsCompletedWithNotification(int reminderId) async {
    final success = await markReminderAsCompleted(reminderId);
    if (success) {
      final reminder = await getReminderById(reminderId);
      if (reminder != null) {
        await _cancelReminderWithNewSystem(reminder);
      }
    }
    return success;
  }

  /// Tüm hatırlatıcıları yeniden zamanla
  Future<void> rescheduleAllReminders() async {
    final reminders = await getEmployeeReminders(includeCompleted: false);
    for (final reminder in reminders) {
      await _scheduleReminderWithNewSystem(reminder);
    }
  }

  /// Eski hatırlatıcıları otomatik temizle (3 gün geçmiş olanlar)
  Future<int> cleanupOldReminders() async {
    try {
      final now = DateTime.now();
      final cutoffDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 3));

      debugPrint(
        '🧹 Eski hatırlatıcılar temizleniyor (${cutoffDate.toString().split(' ')[0]} öncesi)...',
      );

      final allReminders = await getEmployeeReminders(includeCompleted: false);
      int deletedCount = 0;

      for (final reminder in allReminders) {
        final reminderDate = DateTime(
          reminder.reminderDate.year,
          reminder.reminderDate.month,
          reminder.reminderDate.day,
        );

        // Hatırlatıcı tarihi cutoff tarihinden önceyse sil
        if (reminderDate.isBefore(cutoffDate)) {
          if (reminder.id != null) {
            final success = await deleteEmployeeReminderWithNotification(
              reminder.id!,
            );
            if (success) {
              deletedCount++;
              debugPrint(
                '🗑️ Eski hatırlatıcı silindi: ${reminder.workerName} - ${reminder.reminderDate}',
              );
            }
          }
        }
      }

      debugPrint('Toplam $deletedCount eski hatırlatıcı temizlendi');
      return deletedCount;
    } catch (e) {
      debugPrint('Eski hatırlatıcılar temizlenirken hata: $e');
      return 0;
    }
  }

  /// Tamamlanmış eski hatırlatıcıları temizle (30 gün geçmiş)
  Future<int> cleanupCompletedReminders() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));

      debugPrint(
        '🧹 Tamamlanmış eski hatırlatıcılar temizleniyor (${cutoffDate.toString().split(' ')[0]} öncesi)...',
      );

      final allReminders = await getEmployeeReminders(includeCompleted: true);
      int deletedCount = 0;

      for (final reminder in allReminders) {
        // Tamamlanmış ve hatırlatıcı tarihi 30 gün öncesinden eskiyse sil
        if (reminder.isCompleted &&
            reminder.reminderDate.isBefore(cutoffDate)) {
          if (reminder.id != null) {
            final success = await deleteEmployeeReminder(reminder.id!);
            if (success) {
              deletedCount++;
              debugPrint(
                '🗑️ Tamamlanmış eski hatırlatıcı silindi: ${reminder.workerName} - ${reminder.reminderDate}',
              );
            }
          }
        }
      }

      debugPrint('Toplam $deletedCount tamamlanmış hatırlatıcı temizlendi');
      return deletedCount;
    } catch (e) {
      debugPrint('Tamamlanmış hatırlatıcılar temizlenirken hata: $e');
      return 0;
    }
  }

  /// Yeni bildirim sistemi ile hatırlatıcı zamanla
  Future<void> _scheduleReminderWithNewSystem(EmployeeReminder reminder) async {
    try {
      if (reminder.id == null) {
        debugPrint('⚠️ Hatırlatıcı ID\'si null, bildirim zamanlanamadı');
        return;
      }

      // Kullanıcı bilgilerini al
      final userData = await getUserData(reminder.userId);
      final username = userData['username'] as String? ?? 'kullanıcı';
      final firstName = userData['first_name'] as String? ?? '';
      final lastName = userData['last_name'] as String? ?? '';
      final fullName = '$firstName $lastName'.trim();

      // Yeni bildirim servisi ile zamanla
      await _notificationServiceV2.scheduleEmployeeReminder(
        reminderId: reminder.id!,
        userId: reminder.userId,
        username: username,
        fullName: fullName,
        workerName: reminder.workerName,
        message: reminder.message,
        reminderDate: reminder.reminderDate,
      );

      debugPrint(
        '✅ Çalışan hatırlatıcısı yeni sistem ile zamanlandı: ID=${reminder.id}',
      );
    } catch (e) {
      debugPrint('Çalışan hatırlatıcısı zamanlanırken hata: $e');
    }
  }

  /// Yeni bildirim sistemi ile hatırlatıcı iptal et
  Future<void> _cancelReminderWithNewSystem(EmployeeReminder reminder) async {
    try {
      if (reminder.id != null) {
        await _notificationServiceV2.cancelNotification(reminder.id!);
        debugPrint('Çalışan hatırlatıcısı iptal edildi: ID=${reminder.id}');
      }
    } catch (e) {
      debugPrint('Çalışan hatırlatıcısı iptal edilirken hata: $e');
    }
  }
}
