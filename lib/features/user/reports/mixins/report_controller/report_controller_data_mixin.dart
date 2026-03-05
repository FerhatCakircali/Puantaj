import 'package:flutter/material.dart';

import '../../../../../models/attendance.dart' as attendance;
import '../../../../../models/employee.dart';
import '../../../../../services/attendance_service.dart';
import '../../../../../services/payment_service.dart';
import '../../../../../services/worker_service.dart';
import 'report_controller_helpers.dart';

/// Veri yükleme ve filtreleme işlemleri mixin'i
mixin ReportControllerDataMixin<T extends StatefulWidget> on State<T> {
  final WorkerService workerService = WorkerService();
  final AttendanceService attendanceService = AttendanceService();
  final PaymentService paymentService = PaymentService();

  List<Employee> get employees;
  List<Employee> get filteredEmployees;
  Map<int, Map<String, dynamic>> get statsMap;
  bool get isLoading;
  DateTime get startDate;
  DateTime get endDate;

  set employees(List<Employee> value);
  set filteredEmployees(List<Employee> value);
  set statsMap(Map<int, Map<String, dynamic>> value);
  set isLoading(bool value);

  /// Verileri yükle
  Future<void> loadData() async {
    if (!mounted) return;

    debugPrint('📊 ReportControllerMixin: Veriler yükleniyor');

    setState(() => isLoading = true);

    try {
      final allEmployees = await workerService.getEmployees();

      debugPrint('📊 Toplam ${allEmployees.length} çalışan bulundu');

      final allAttendance = await attendanceService.getAttendanceBetween(
        startDate,
        endDate,
      );

      debugPrint('📊 Dönem içi ${allAttendance.length} yevmiye kaydı bulundu');

      final attendanceMap = <int, List<attendance.Attendance>>{};

      for (var record in allAttendance) {
        attendanceMap.putIfAbsent(record.workerId, () => []).add(record);
      }

      // ✅ TÜM çalışanları göster (yevmiye kaydı olsun veya olmasın)
      final newStatsMap = <int, Map<String, dynamic>>{};
      for (var emp in allEmployees) {
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

      allEmployees.sort(
        (a, b) => ReportControllerHelpers.collateTurkish(a.name, b.name),
      );

      if (!mounted) return;

      setState(() {
        employees = allEmployees;
        filteredEmployees = allEmployees;
        statsMap = newStatsMap;
        isLoading = false;
      });

      debugPrint(
        '✅ ReportControllerMixin: ${employees.length} çalışan yüklendi',
      );
    } catch (e) {
      debugPrint('❌ ReportControllerMixin: Veri yükleme hatası: $e');

      if (!mounted) return;

      setState(() => isLoading = false);
    }
  }

  /// Çalışanları filtrele
  void filterEmployees(String query) {
    if (!mounted) return;

    debugPrint('🔍 ReportControllerMixin: Arama sorgusu: "$query"');

    setState(() {
      if (query.isEmpty) {
        filteredEmployees = employees;
      } else {
        filteredEmployees = employees.where((employee) {
          final name = employee.name.toLowerCase();
          final title = employee.title.toLowerCase();
          final lowerQuery = query.toLowerCase();
          return name.contains(lowerQuery) || title.contains(lowerQuery);
        }).toList();
      }
    });

    debugPrint('✅ ReportControllerMixin: ${filteredEmployees.length} sonuç');
  }
}
