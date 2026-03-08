import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/attendance.dart' as attendance;
import '../../../../models/employee.dart';
import '../../../../services/attendance_service.dart';
import '../widgets/attendance_notification_handler.dart';

/// Yoklama kaydetme işlemlerini yöneten sınıf
///
/// Yoklama değişikliklerini kaydeder ve bildirimleri gönderir
class AttendanceSaveHandler {
  final AttendanceService _attendanceService = AttendanceService();

  /// Yoklama değişikliklerini kaydeder
  Future<SaveResult> saveChanges({
    required BuildContext context,
    required DateTime selectedDate,
    required List<Employee> filteredEmployees,
    required Map<int, attendance.Attendance> attendanceMap,
    required Map<int, attendance.AttendanceStatus> pendingChanges,
    required List<Employee> allEmployees,
  }) async {
    debugPrint('[Attendance] saveChanges başladı');
    debugPrint('[Attendance] Pending changes: $pendingChanges');

    final unselectedEmployees = _findUnselectedEmployees(
      filteredEmployees,
      pendingChanges,
      attendanceMap,
    );

    if (unselectedEmployees.isNotEmpty) {
      final confirmed = await _showUnselectedConfirmation(
        context,
        unselectedEmployees.length,
      );

      if (!confirmed) {
        debugPrint('[Attendance] Kullanıcı işlemi iptal etti');
        return SaveResult.cancelled();
      }

      for (final employee in unselectedEmployees) {
        pendingChanges[employee.id] = attendance.AttendanceStatus.absent;
      }
      debugPrint(
        '[Attendance] ${unselectedEmployees.length} çalışan "gelmedi" olarak eklendi',
      );
    }

    if (pendingChanges.isEmpty) {
      debugPrint('[Attendance] Kaydedilecek değişiklik yok');
      return SaveResult.noChanges();
    }

    try {
      await _saveAttendanceRecords(selectedDate, pendingChanges);
      await _updateNotificationStatus(selectedDate);
      await _sendNotifications(
        selectedDate,
        pendingChanges,
        allEmployees,
        attendanceMap,
      );

      return SaveResult.success(unselectedCount: unselectedEmployees.length);
    } catch (e) {
      debugPrint('[Attendance] Yevmiye kaydetme hatası: $e');
      return SaveResult.error(e.toString());
    }
  }

  List<Employee> _findUnselectedEmployees(
    List<Employee> filteredEmployees,
    Map<int, attendance.AttendanceStatus> pendingChanges,
    Map<int, attendance.Attendance> attendanceMap,
  ) {
    return filteredEmployees.where((employee) {
      final hasPendingChange = pendingChanges.containsKey(employee.id);
      final hasAttendanceRecord = attendanceMap.containsKey(employee.id);
      return !hasPendingChange && !hasAttendanceRecord;
    }).toList();
  }

  Future<bool> _showUnselectedConfirmation(
    BuildContext context,
    int count,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dikkat'),
        content: Text(
          '$count çalışan için durum seçilmedi.\n\n'
          'Bu çalışanlar otomatik olarak "Gelmedi" olarak kaydedilecek.\n\n'
          'Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  Future<void> _saveAttendanceRecords(
    DateTime selectedDate,
    Map<int, attendance.AttendanceStatus> pendingChanges,
  ) async {
    for (final entry in pendingChanges.entries) {
      debugPrint(
        '[Attendance] Kaydediliyor: Worker ${entry.key} -> ${entry.value}',
      );
      await _attendanceService.markAttendance(
        workerId: entry.key,
        date: selectedDate,
        status: entry.value,
      );
      debugPrint('[Attendance] Kaydedildi: Worker ${entry.key}');
    }
  }

  Future<void> _updateNotificationStatus(DateTime selectedDate) async {
    final today = DateTime.now();
    final selectedToday = DateTime(today.year, today.month, today.day);
    final selectedDateNorm = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    if (selectedDateNorm.isAtSameMomentAs(selectedToday)) {
      debugPrint('[Attendance] Bugünün yevmiye kaydı yapıldı');
      await AttendanceNotificationHandler.markTodayAttendanceDone();
      debugPrint('[Attendance] Bildirim durumu güncellendi');
    }
  }

  Future<void> _sendNotifications(
    DateTime selectedDate,
    Map<int, attendance.AttendanceStatus> pendingChanges,
    List<Employee> allEmployees,
    Map<int, attendance.Attendance> attendanceMap,
  ) async {
    debugPrint('[Attendance] Çalışanlara bildirim gönderiliyor...');
    debugPrint('pendingChanges sayısı: ${pendingChanges.length}');

    try {
      await _sendAttendanceNotificationsToWorkers(
        selectedDate,
        pendingChanges,
        allEmployees,
        attendanceMap,
      );
      debugPrint('[Attendance] Bildirim gönderme tamamlandı');
    } catch (e, stackTrace) {
      debugPrint('[Attendance] Bildirim gönderme HATASI: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _sendAttendanceNotificationsToWorkers(
    DateTime selectedDate,
    Map<int, attendance.AttendanceStatus> pendingChanges,
    List<Employee> allEmployees,
    Map<int, attendance.Attendance> attendanceMap,
  ) async {
    try {
      final now = DateTime.now();
      final formattedDate = DateFormat(
        'dd.MM.yyyy',
        'tr_TR',
      ).format(selectedDate);
      final formattedTime = DateFormat('HH:mm', 'tr_TR').format(now);

      debugPrint('Tarih: $formattedDate, Saat: $formattedTime');
      debugPrint(
        'Bildirim gönderilecek çalışan sayısı: ${pendingChanges.length}',
      );

      for (final entry in pendingChanges.entries) {
        final workerId = entry.key;
        final newStatus = entry.value;
        final employee = allEmployees.firstWhere((e) => e.id == workerId);

        final oldAttendance = attendanceMap[workerId];
        final isUpdate = oldAttendance != null;
        final oldStatus = oldAttendance?.status;

        debugPrint('');
        debugPrint('Bildirim gönderiliyor: ${employee.name} (ID: $workerId)');
        debugPrint(
          '  Güncelleme: $isUpdate, Eski: $oldStatus, Yeni: $newStatus',
        );

        if (isUpdate && oldStatus == newStatus) {
          debugPrint('Durum değişmedi, bildirim gönderilmiyor');
          continue;
        }

        try {
          await AttendanceNotificationHandler.sendAttendanceEntryNotification(
            workerId: workerId,
            workerName: employee.name,
            date: formattedDate,
            time: formattedTime,
            isUpdate: isUpdate,
            oldStatus: oldStatus,
            newStatus: newStatus,
          );

          debugPrint('Bildirim gönderildi: ${employee.name}');
        } catch (e, stackTrace) {
          debugPrint('${employee.name} için bildirim HATASI: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      }

      debugPrint('[Attendance] Tüm bildirimler gönderildi');
    } catch (e, stackTrace) {
      debugPrint('[Attendance] Bildirim gönderme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
}

/// Kaydetme sonuç sınıfı
class SaveResult {
  final bool isSuccess;
  final bool isCancelled;
  final bool hasNoChanges;
  final String? errorMessage;
  final int unselectedCount;

  const SaveResult._({
    required this.isSuccess,
    required this.isCancelled,
    required this.hasNoChanges,
    this.errorMessage,
    this.unselectedCount = 0,
  });

  factory SaveResult.success({required int unselectedCount}) {
    return SaveResult._(
      isSuccess: true,
      isCancelled: false,
      hasNoChanges: false,
      unselectedCount: unselectedCount,
    );
  }

  factory SaveResult.cancelled() {
    return const SaveResult._(
      isSuccess: false,
      isCancelled: true,
      hasNoChanges: false,
    );
  }

  factory SaveResult.noChanges() {
    return const SaveResult._(
      isSuccess: false,
      isCancelled: false,
      hasNoChanges: true,
    );
  }

  factory SaveResult.error(String message) {
    return SaveResult._(
      isSuccess: false,
      isCancelled: false,
      hasNoChanges: false,
      errorMessage: message,
    );
  }

  String getSuccessMessage() {
    if (unselectedCount == 0) {
      return 'Yevmiye kayıtları başarıyla kaydedildi';
    }
    return 'Yevmiye kayıtları başarıyla kaydedildi ($unselectedCount çalışan "gelmedi" olarak işaretlendi)';
  }
}
