import 'package:flutter/material.dart';

import '../../../../data/services/local_storage_service.dart';
import '../../../../models/attendance.dart';
import '../../services/worker_attendance_service.dart';
import '../../services/worker_notification_service.dart';
import 'worker_reminders_helpers.dart';

/// Business logic mixin - WorkerRemindersScreen
mixin WorkerRemindersLogicMixin<T extends StatefulWidget> on State<T> {
  final localStorage = LocalStorageService.instance;
  final notificationService = WorkerNotificationService();
  final attendanceService = WorkerAttendanceService();

  bool isLoading = true;
  int? workerId;

  Map<String, dynamic>? todayStatus;

  bool reminderEnabled = false;
  TimeOfDay reminderTime = const TimeOfDay(hour: 18, minute: 0);

  /// Tüm verileri yükler
  Future<void> loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final session = await localStorage.getWorkerSession();

      if (session == null) {
        return;
      }

      workerId = int.parse(session['workerId']!);

      final todayStatusData = await attendanceService.checkTodayStatus(
        workerId!,
      );

      final settings = await notificationService.getReminderSettings(workerId!);

      if (settings != null) {
        final timeStr = settings['time'] as String;
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final enabled = settings['enabled'] as bool;

        if (!mounted) return;
        setState(() {
          reminderEnabled = enabled;
          reminderTime = TimeOfDay(hour: hour, minute: minute);
        });

        // Hatırlatıcı aktifse ve uygulama yeni açıldıysa yeniden zamanla
        if (enabled) {
          final workerName = session['fullName'] ?? 'Çalışan';
          await notificationService.scheduleWorkerAttendanceReminder(
            workerId: workerId!,
            workerName: workerName,
            time: TimeOfDay(hour: hour, minute: minute),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        todayStatus = todayStatusData;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  /// Yevmiye girişi yapar
  Future<void> submitAttendance(AttendanceStatus status) async {
    if (workerId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yevmiye Girişi'),
        content: Text(
          'Bugün için ${WorkerRemindersHelpers.getStatusText(status)} olarak yevmiye girişi yapmak istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Çalışan adını al
    final session = await localStorage.getWorkerSession();
    final workerName = session?['fullName'] ?? 'Çalışan';

    // userId artık opsiyonel - workers tablosundan alınacak
    final success = await attendanceService.submitAttendanceRequest(
      workerId: workerId!,
      date: DateTime.now(),
      status: status,
      workerName: workerName,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yevmiye talebi gönderildi')),
        );
        loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yevmiye talebi gönderilemedi')),
        );
      }
    }
  }

  /// Hatırlatıcı ayarlarını kaydeder
  Future<void> saveSettings() async {
    if (workerId == null) return;

    final timeStr = WorkerRemindersHelpers.formatTimeOfDayToString(
      reminderTime.hour,
      reminderTime.minute,
    );

    final success = await notificationService.saveReminderSettings(
      workerId: workerId!,
      time: timeStr,
      enabled: reminderEnabled,
    );

    if (success) {
      // Bildirim zamanla veya iptal et
      if (reminderEnabled) {
        // Çalışan bilgilerini al
        final session = await localStorage.getWorkerSession();
        final workerName = session?['fullName'] ?? 'Çalışan';

        // Hatırlatıcıyı zamanla
        await notificationService.scheduleWorkerAttendanceReminder(
          workerId: workerId!,
          workerName: workerName,
          time: reminderTime,
        );
      } else {
        // Hatırlatıcıyı iptal et
        await notificationService.cancelWorkerAttendanceReminder(workerId!);
      }
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reminderEnabled
                  ? 'Hatırlatıcı ayarları kaydedildi. Her gün ${WorkerRemindersHelpers.formatTimeOfDayForDisplay(reminderTime.hour, reminderTime.minute)} saatinde bildirim alacaksınız.'
                  : 'Hatırlatıcı kapatıldı',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ayarlar kaydedilemedi')));
      }
    }
  }

  /// Saat seçici gösterir
  Future<void> selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminderTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => reminderTime = picked);
    }
  }
}
