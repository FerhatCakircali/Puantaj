import 'package:flutter/material.dart';

import '../../../../../models/attendance.dart' as attendance;
import '../../../../../models/employee.dart';
import '../../../../../services/attendance_service.dart';
import '../../../../../services/payment_service.dart';
import '../../../../../services/worker_service.dart';
import 'report_controller_helpers.dart';

/// Veri yükleme ve filtreleme operasyonları
class ReportControllerDataOperations {
  /// Verileri yükle
  static Future<void> loadData({
    required State context,
    required WorkerService workerService,
    required AttendanceService attendanceService,
    required PaymentService paymentService,
    required DateTime startDate,
    required DateTime endDate,
    required void Function(
      List<Employee>,
      List<Employee>,
      Map<int, Map<String, dynamic>>,
      bool,
    )
    onUpdate,
  }) async {
    if (!context.mounted) return;

    debugPrint('📊 ReportControllerMixin: Veriler yükleniyor');

    onUpdate([], [], {}, true);

    try {
      final allEmployees = await workerService.getEmployees();
      final allAttendance = await attendanceService.getAttendanceBetween(
        startDate,
        endDate,
      );

      final attendanceMap = <int, List<attendance.Attendance>>{};
      final activeWorkerIds = <int>{};

      for (var record in allAttendance) {
        attendanceMap.putIfAbsent(record.workerId, () => []).add(record);
        activeWorkerIds.add(record.workerId);
      }

      final activeEmployees = allEmployees
          .where((emp) => activeWorkerIds.contains(emp.id))
          .toList();

      final newStatsMap = <int, Map<String, dynamic>>{};
      for (var emp in activeEmployees) {
        final records = attendanceMap[emp.id] ?? [];
        final unpaidDays = await paymentService.getUnpaidDays(emp.id);
        newStatsMap[emp.id] = ReportControllerHelpers.calculateAttendanceStats(
          emp,
          records,
          startDate,
          endDate,
          unpaidDays,
        );
      }

      activeEmployees.sort(
        (a, b) => ReportControllerHelpers.collateTurkish(a.name, b.name),
      );

      if (!context.mounted) return;

      onUpdate(activeEmployees, activeEmployees, newStatsMap, false);

      debugPrint(
        '✅ ReportControllerMixin: ${activeEmployees.length} çalışan yüklendi',
      );
    } catch (e) {
      debugPrint('❌ ReportControllerMixin: Veri yükleme hatası: $e');

      if (!context.mounted) return;

      onUpdate([], [], {}, false);
    }
  }

  /// Çalışanları filtrele
  static void filterEmployees({
    required State context,
    required String query,
    required List<Employee> employees,
    required void Function(List<Employee>) onUpdate,
  }) {
    if (!context.mounted) return;

    debugPrint('🔍 ReportControllerMixin: Arama sorgusu: "$query"');

    List<Employee> filtered;
    if (query.isEmpty) {
      filtered = employees;
    } else {
      filtered = employees.where((employee) {
        final name = employee.name.toLowerCase();
        final title = employee.title.toLowerCase();
        final lowerQuery = query.toLowerCase();
        return name.contains(lowerQuery) || title.contains(lowerQuery);
      }).toList();
    }

    onUpdate(filtered);

    debugPrint('✅ ReportControllerMixin: ${filtered.length} sonuç');
  }
}
