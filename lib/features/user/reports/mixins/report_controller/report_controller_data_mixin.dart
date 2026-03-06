import 'package:flutter/material.dart';

import '../../../../../models/attendance.dart' as attendance;
import '../../../../../models/employee.dart';
import '../../../../../services/attendance_service.dart';
import '../../../../../services/payment_service.dart';
import '../../../../../services/worker_service.dart';
import '../../../../../data/local/hive_service.dart';
import 'report_controller_helpers.dart';

/// Veri yükleme ve filtreleme işlemleri mixin'i
mixin ReportControllerDataMixin<T extends StatefulWidget> on State<T> {
  final WorkerService workerService = WorkerService();
  final AttendanceService attendanceService = AttendanceService();
  final PaymentService paymentService = PaymentService();
  final _hiveService = HiveService.instance;

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

  /// Verileri yükle (Optimized - Hive cache + paralel queries)
  Future<void> loadData() async {
    if (!mounted) return;

    debugPrint('ReportControllerMixin: Veriler yükleniyor');

    setState(() => isLoading = true);

    try {
      // 1. Önce cache'den employees al (hızlı)
      final cachedEmployees = _hiveService.employees.values.toList();

      if (cachedEmployees.isNotEmpty) {
        debugPrint('⚡ Cache\'den ${cachedEmployees.length} çalışan yüklendi');

        // Arka planda gerçek veriyi çek (non-blocking)
        _loadDataInBackground();

        // Cache'den hızlı sonuç göster
        await _processReportData(cachedEmployees);
        return;
      }

      // Cache yoksa normal yükle
      final allEmployees = await workerService.getEmployees();
      await _processReportData(allEmployees);
    } catch (e) {
      debugPrint('ReportControllerMixin: Veri yükleme hatası: $e');

      if (!mounted) return;

      setState(() => isLoading = false);
    }
  }

  /// Arka planda veri güncelle (non-blocking)
  Future<void> _loadDataInBackground() async {
    try {
      final freshEmployees = await workerService.getEmployees();
      if (!mounted) return;
      await _processReportData(freshEmployees);
    } catch (e) {
      debugPrint('Arka plan güncelleme hatası: $e');
    }
  }

  /// Report verilerini işle (paralel queries ile optimize edildi)
  Future<void> _processReportData(List<Employee> allEmployees) async {
    debugPrint('Toplam ${allEmployees.length} çalışan bulundu');

    final allAttendance = await attendanceService.getAttendanceBetween(
      startDate,
      endDate,
    );

    debugPrint('Dönem içi ${allAttendance.length} yevmiye kaydı bulundu');

    final attendanceMap = <int, List<attendance.Attendance>>{};

    for (var record in allAttendance) {
      attendanceMap.putIfAbsent(record.workerId, () => []).add(record);
    }

        final unpaidDaysFutures = allEmployees.map((emp) async {
      try {
        final unpaidDays = await paymentService.getUnpaidDays(emp.id);
        return MapEntry(emp.id, unpaidDays);
      } catch (e) {
        debugPrint('${emp.name} için unpaid days alınamadı: $e');
        return MapEntry(emp.id, {'fullDays': 0, 'halfDays': 0});
      }
    });

    final unpaidDaysResults = await Future.wait(unpaidDaysFutures);
    final unpaidDaysMap = Map.fromEntries(unpaidDaysResults);

    // Stats hesapla
    final newStatsMap = <int, Map<String, dynamic>>{};
    for (var emp in allEmployees) {
      final records = attendanceMap[emp.id] ?? [];
      final unpaidDays =
          unpaidDaysMap[emp.id] ?? {'fullDays': 0, 'halfDays': 0};
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

    debugPrint('ReportControllerMixin: ${employees.length} çalışan yüklendi');
  }

  /// Çalışanları filtrele
  void filterEmployees(String query) {
    if (!mounted) return;

    debugPrint('ReportControllerMixin: Arama sorgusu: "$query"');

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

    debugPrint('ReportControllerMixin: ${filteredEmployees.length} sonuç');
  }
}
