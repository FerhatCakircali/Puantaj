import 'package:flutter/material.dart';
import '../../../../models/attendance.dart' as attendance;
import '../../../../models/employee.dart';
import '../widgets/attendance_notification_handler.dart';

/// Yoklama hatırlatma işlemlerini yöneten sınıf
///
/// Yevmiye yapmamış çalışanlara hatırlatma gönderir
class AttendanceReminderHandler {
  /// Yevmiye yapmamış çalışanlara hatırlatma gönderir
  ///
  /// Sadece bugün için hatırlatma gönderilebilir
  Future<ReminderResult> sendReminders({
    required BuildContext context,
    required DateTime selectedDate,
    required List<Employee> employees,
    required Map<int, attendance.AttendanceStatus> pendingChanges,
    required Map<int, attendance.Attendance> attendanceMap,
  }) async {
    if (!_isTodaySelected(selectedDate)) {
      return ReminderResult.notToday();
    }

    final workersWithoutAttendance = _findWorkersWithoutAttendance(
      employees,
      pendingChanges,
      attendanceMap,
    );

    if (workersWithoutAttendance.isEmpty) {
      return ReminderResult.allDone();
    }

    final confirmed = await _showConfirmation(
      context,
      workersWithoutAttendance.length,
    );

    if (!confirmed) {
      return ReminderResult.cancelled();
    }

    try {
      await AttendanceNotificationHandler.sendRemindersToWorkers(
        context,
        workersWithoutAttendance,
      );

      return ReminderResult.success(workersWithoutAttendance.length);
    } catch (e) {
      debugPrint('Hatırlatma gönderme hatası: $e');
      return ReminderResult.error(e.toString());
    }
  }

  bool _isTodaySelected(DateTime selectedDate) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final selectedDateNorm = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    return selectedDateNorm.isAtSameMomentAs(todayDate);
  }

  List<Employee> _findWorkersWithoutAttendance(
    List<Employee> employees,
    Map<int, attendance.AttendanceStatus> pendingChanges,
    Map<int, attendance.Attendance> attendanceMap,
  ) {
    return employees.where((employee) {
      final hasPendingChange = pendingChanges.containsKey(employee.id);
      final hasAttendanceRecord = attendanceMap.containsKey(employee.id);
      return !hasPendingChange && !hasAttendanceRecord;
    }).toList();
  }

  Future<bool> _showConfirmation(BuildContext context, int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hatırlatma Gönder'),
        content: Text(
          '$count çalışana yevmiye hatırlatması göndermek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hayır'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Evet'),
          ),
        ],
      ),
    );

    return confirmed == true;
  }
}

/// Hatırlatma sonuç sınıfı
class ReminderResult {
  final bool isSuccess;
  final String? message;
  final int workerCount;
  final Color? backgroundColor;

  const ReminderResult._({
    required this.isSuccess,
    this.message,
    this.workerCount = 0,
    this.backgroundColor,
  });

  factory ReminderResult.success(int count) {
    return ReminderResult._(
      isSuccess: true,
      message: '$count çalışana hatırlatma gönderildi',
      workerCount: count,
      backgroundColor: Colors.green,
    );
  }

  factory ReminderResult.notToday() {
    return const ReminderResult._(
      isSuccess: false,
      message: 'Hatırlatma sadece bugün için gönderilebilir',
      backgroundColor: Colors.orange,
    );
  }

  factory ReminderResult.allDone() {
    return const ReminderResult._(
      isSuccess: false,
      message: 'Tüm çalışanlar yevmiye girişi yapmış',
      backgroundColor: Colors.green,
    );
  }

  factory ReminderResult.cancelled() {
    return const ReminderResult._(isSuccess: false);
  }

  factory ReminderResult.error(String error) {
    return ReminderResult._(
      isSuccess: false,
      message: 'Hatırlatma gönderilirken hata oluştu: $error',
      backgroundColor: Colors.red,
    );
  }
}
