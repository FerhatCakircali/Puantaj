import 'package:flutter/material.dart';
import '../../../../models/employee_reminder.dart';
import 'notification_state_mixin.dart';
import 'notification_data/loaders/worker_loader.dart';
import 'notification_data/loaders/settings_loader.dart';
import 'notification_data/loaders/reminder_loader.dart';
import 'notification_data/savers/settings_saver.dart';
import 'notification_data/handlers/reminder_scheduler.dart';

/// Notification Settings ekranı için data operations mixin'i
///
/// Veri yükleme, kaydetme ve filtreleme işlemlerini koordine eder
mixin NotificationDataMixin<T extends StatefulWidget>
    on NotificationStateMixin<T> {
  final WorkerLoader _workerLoader = WorkerLoader();
  final SettingsLoader _settingsLoader = SettingsLoader();
  final ReminderLoader _reminderLoader = ReminderLoader();
  final SettingsSaver _settingsSaver = SettingsSaver();
  final ReminderScheduler _reminderScheduler = ReminderScheduler();

  /// Çalışanları yükler
  Future<void> loadWorkers() async {
    setState(() {
      isLoadingWorkers = true;
    });

    try {
      final loadedWorkers = await _workerLoader.loadWorkers();
      setState(() {
        workers = loadedWorkers;
        filteredWorkers = loadedWorkers;
      });
    } catch (e) {
      showSnackBar('Çalışanlar yüklenirken bir hata oluştu');
    } finally {
      setState(() {
        isLoadingWorkers = false;
      });
    }
  }

  /// Çalışanları ve hatırlatıcıları filtreler
  void filterWorkers(String query) {
    setState(() {
      filteredWorkers = WorkerLoader.filterByQuery(
        workers,
        query,
        (worker) => worker.fullName,
      );
      filteredReminders = WorkerLoader.filterByQuery(
        reminders,
        query,
        (reminder) => reminder.workerName,
      );
    });
  }

  /// Bildirim ayarlarını yükler
  Future<void> loadSettings() async {
    setState(() {
      isLoading = true;
    });

    try {
      final loadedSettings = await _settingsLoader.loadSettings();

      if (loadedSettings != null) {
        setState(() {
          settings = loadedSettings;
          isEnabled = loadedSettings.enabled;
          autoApproveTrusted = loadedSettings.autoApproveTrusted;
          attendanceRequestsEnabled = loadedSettings.attendanceRequestsEnabled;
          selectedTime = loadedSettings.time;
        });
      } else {
        final defaults = SettingsLoader.getDefaultSettings();
        setState(() {
          settings = null;
          isEnabled = defaults['isEnabled'] as bool;
          autoApproveTrusted = defaults['autoApproveTrusted'] as bool;
          attendanceRequestsEnabled =
              defaults['attendanceRequestsEnabled'] as bool;
          selectedTime = defaults['selectedTime'] as String;
        });
      }
    } catch (e) {
      showSnackBar('Ayarlar yüklenirken bir hata oluştu');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Bildirim ayarlarını kaydeder
  Future<void> saveSettings() async {
    setState(() {
      isLoading = true;
    });

    try {
      final success = await _settingsSaver.saveSettings(
        currentSettings: settings,
        isEnabled: isEnabled,
        autoApproveTrusted: autoApproveTrusted,
        attendanceRequestsEnabled: attendanceRequestsEnabled,
        selectedTime: selectedTime,
      );

      if (success) {
        if (isEnabled) {
          await _reminderScheduler.scheduleAttendanceReminder(selectedTime);
        } else {
          await _reminderScheduler.cancelAttendanceReminder();
        }

        final message = await _settingsSaver.getSaveSuccessMessage(
          isEnabled: isEnabled,
          selectedTime: selectedTime,
        );
        showSnackBar(message);

        await loadSettings();
      } else {
        showSnackBar('Bildirim ayarları kaydedilirken bir hata oluştu');
      }
    } catch (e) {
      showSnackBar('Ayarlar kaydedilirken bir hata oluştu: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Hatırlatıcıları yükler
  Future<void> loadReminders() async {
    final requestId = ++remindersLoadRequestId;
    setState(() {
      isLoadingReminders = true;
    });

    try {
      final loadedReminders = await _reminderLoader.loadReminders();

      if (!mounted || requestId != remindersLoadRequestId) return;

      setState(() {
        reminders = ReminderLoader.filterPendingDeletes(
          loadedReminders,
          pendingDeleteReminderIds,
        );
        filteredReminders = reminders;
      });
    } catch (e) {
      showSnackBar('Hatırlatıcılar yüklenirken bir hata oluştu');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingReminders = false;
        });
      }
    }
  }

  /// Hatırlatıcıyı siler
  Future<void> deleteReminder(int listIndex, EmployeeReminder reminder) async {
    if (reminder.id == null) return;

    final reminderId = reminder.id!;

    pendingDeleteReminderIds.add(reminderId);

    setState(() {
      reminders.removeWhere((r) => r.id == reminderId);
    });

    try {
      final success = await _reminderLoader.deleteReminder(reminderId);
      if (success) {
        pendingDeleteReminderIds.remove(reminderId);
        showSnackBar('Hatırlatıcı silindi');
        await loadReminders();
      } else {
        _revertReminderDelete(listIndex, reminder, reminderId);
        showSnackBar('Hatırlatıcı silinirken bir hata oluştu');
      }
    } catch (e) {
      _revertReminderDelete(listIndex, reminder, reminderId);
      showSnackBar('Hatırlatıcı silinirken bir hata oluştu');
    }
  }

  void _revertReminderDelete(
    int listIndex,
    EmployeeReminder reminder,
    int reminderId,
  ) {
    pendingDeleteReminderIds.remove(reminderId);
    setState(() {
      final safeIndex = listIndex.clamp(0, reminders.length);
      reminders.insert(safeIndex, reminder);
    });
  }
}
