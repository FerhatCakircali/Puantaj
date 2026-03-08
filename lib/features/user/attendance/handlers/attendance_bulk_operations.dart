import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/attendance.dart' as attendance;
import '../../../../models/employee.dart';
import '../../../../services/payment_service.dart';

/// Toplu yoklama işlemlerini yöneten sınıf
///
/// Tüm çalışanların durumunu toplu olarak değiştirir
class AttendanceBulkOperations {
  final PaymentService _paymentService = PaymentService();

  /// Tüm çalışanların durumunu toplu olarak değiştir
  Future<BulkChangeResult> bulkChangeStatus({
    required BuildContext context,
    required DateTime selectedDate,
    required List<Employee> filteredEmployees,
    required Map<int, attendance.AttendanceStatus> pendingChanges,
    required Map<int, attendance.Attendance> attendanceMap,
    required attendance.AttendanceStatus status,
  }) async {
    final paidEmployees = <String>[];
    final notStartedEmployees = <String>[];
    int changedCount = 0;

    for (final employee in filteredEmployees) {
      if (selectedDate.isBefore(employee.startDate)) {
        notStartedEmployees.add(employee.name);
        continue;
      }

      final currentStatus =
          pendingChanges[employee.id] ?? attendanceMap[employee.id]?.status;

      if (currentStatus != null && currentStatus != status) {
        final isPaid = await _paymentService.isDayPaid(
          employee.id,
          selectedDate,
          currentStatus,
        );

        if (isPaid) {
          paidEmployees.add(employee.name);
          continue;
        }
      }

      pendingChanges[employee.id] = status;
      changedCount++;
    }

    return BulkChangeResult(
      changedCount: changedCount,
      paidEmployees: paidEmployees,
      notStartedEmployees: notStartedEmployees,
      status: status,
    );
  }

  /// Tek bir çalışanın durumunu değiştirir
  Future<StatusChangeResult> changeStatus({
    required BuildContext context,
    required int workerId,
    required DateTime selectedDate,
    required List<Employee> employees,
    required Map<int, attendance.AttendanceStatus> pendingChanges,
    required Map<int, attendance.Attendance> attendanceMap,
    required attendance.AttendanceStatus value,
  }) async {
    final employee = employees.firstWhere((e) => e.id == workerId);

    if (selectedDate.isBefore(employee.startDate)) {
      return StatusChangeResult.beforeStartDate(
        employeeName: employee.name,
        startDate: employee.startDate,
      );
    }

    final currentStatus =
        pendingChanges[workerId] ?? attendanceMap[workerId]?.status;

    if (currentStatus != null && currentStatus != value) {
      final isPaid = await _paymentService.isDayPaid(
        workerId,
        selectedDate,
        currentStatus,
      );

      if (isPaid) {
        return StatusChangeResult.alreadyPaid();
      }
    }

    pendingChanges[workerId] = value;
    return StatusChangeResult.success();
  }
}

/// Toplu değişiklik sonuç sınıfı
class BulkChangeResult {
  final int changedCount;
  final List<String> paidEmployees;
  final List<String> notStartedEmployees;
  final attendance.AttendanceStatus status;

  const BulkChangeResult({
    required this.changedCount,
    required this.paidEmployees,
    required this.notStartedEmployees,
    required this.status,
  });

  String getStatusText() {
    return status == attendance.AttendanceStatus.fullDay
        ? 'Tam Gün'
        : status == attendance.AttendanceStatus.halfDay
        ? 'Yarım Gün'
        : 'Gelmedi';
  }

  bool get hasPaidEmployees => paidEmployees.isNotEmpty;
  bool get hasNotStartedEmployees => notStartedEmployees.isNotEmpty;
  bool get hasChanges => changedCount > 0;

  String getPaidEmployeesMessage() {
    return '${paidEmployees.length} çalışan için ödeme yapılmış, değiştirilemedi:\n${paidEmployees.take(3).join(", ")}${paidEmployees.length > 3 ? "..." : ""}';
  }

  String getNotStartedEmployeesMessage() {
    return '${notStartedEmployees.length} çalışan henüz işe başlamamış:\n${notStartedEmployees.take(3).join(", ")}${notStartedEmployees.length > 3 ? "..." : ""}';
  }

  String getSuccessMessage() {
    return '$changedCount çalışan "${getStatusText()}" olarak işaretlendi';
  }
}

/// Durum değişikliği sonuç sınıfı
class StatusChangeResult {
  final bool isSuccess;
  final String? errorMessage;
  final Color? backgroundColor;

  const StatusChangeResult._({
    required this.isSuccess,
    this.errorMessage,
    this.backgroundColor,
  });

  factory StatusChangeResult.success() {
    return const StatusChangeResult._(isSuccess: true);
  }

  factory StatusChangeResult.beforeStartDate({
    required String employeeName,
    required DateTime startDate,
  }) {
    return StatusChangeResult._(
      isSuccess: false,
      errorMessage:
          '$employeeName işe başlama tarihinden (${DateFormat('dd/MM/yyyy').format(startDate)}) önceki tarihlerde yevmiye girişi yapılamaz.',
      backgroundColor: Colors.orange,
    );
  }

  factory StatusChangeResult.alreadyPaid() {
    return const StatusChangeResult._(
      isSuccess: false,
      errorMessage: 'Bu gün için ödeme yapılmış, durum değiştirilemez!',
      backgroundColor: Colors.red,
    );
  }
}
