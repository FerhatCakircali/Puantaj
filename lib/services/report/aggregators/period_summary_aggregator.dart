import 'package:flutter/foundation.dart';
import '../../../models/employee.dart';
import '../../../services/worker_service.dart';
import '../../../core/di/service_locator.dart';
import '../models/period_range.dart';
import '../calculators/attendance_summary_calculator.dart';
import '../calculators/period_calculator.dart';

/// Dönemsel özet toplama sınıfı
class PeriodSummaryAggregator {
  final WorkerService _workerService;
  final AttendanceSummaryCalculator _summaryCalculator;

  PeriodSummaryAggregator({
    WorkerService? workerService,
    AttendanceSummaryCalculator? summaryCalculator,
  }) : _workerService = workerService ?? getIt<WorkerService>(),
       _summaryCalculator =
           summaryCalculator ?? getIt<AttendanceSummaryCalculator>();

  /// Tüm çalışanlar için dönemsel özet rapor oluşturur
  Future<Map<String, dynamic>> aggregate(
    ReportPeriod period, {
    DateTime? referenceDate,
    DateTime? customStart,
    DateTime? customEnd,
    int? specificEmployeeId,
  }) async {
    try {
      final periodRange = PeriodCalculator.calculate(
        period,
        referenceDate: referenceDate,
        customStart: customStart,
        customEnd: customEnd,
      );

      final employees = await _getEmployees(specificEmployeeId);

      // Her çalışan için dönemsel özet topla
      final employeeSummaries = await _collectEmployeeSummaries(
        employees,
        periodRange,
      );

      // Genel totalleri hesapla
      final totals = _calculateTotals(employeeSummaries);

      return {
        'periodRange': periodRange,
        'employees': employees,
        'employeeSummaries': employeeSummaries,
        'totals': totals,
      };
    } catch (e, stackTrace) {
      debugPrint('PeriodSummaryAggregator.aggregate hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      return _getEmptyResult(period, referenceDate, customStart, customEnd);
    }
  }

  /// Çalışanları getirir (tümü veya belirli bir çalışan)
  Future<List<Employee>> _getEmployees(int? specificEmployeeId) async {
    final allEmployees = await _workerService.getEmployees();

    if (specificEmployeeId != null) {
      return allEmployees.where((e) => e.id == specificEmployeeId).toList();
    }

    return allEmployees;
  }

  /// Her çalışan için özet toplar
  Future<List<Map<String, dynamic>>> _collectEmployeeSummaries(
    List<Employee> employees,
    PeriodRange periodRange,
  ) async {
    final summaries = <Map<String, dynamic>>[];

    for (final employee in employees) {
      final summary = await _summaryCalculator.calculate(employee, periodRange);
      summaries.add(summary);
    }

    return summaries;
  }

  /// Genel totalleri hesaplar
  Map<String, dynamic> _calculateTotals(
    List<Map<String, dynamic>> employeeSummaries,
  ) {
    final totalFullDays = employeeSummaries.fold<int>(
      0,
      (sum, summary) => sum + (summary['stats']['fullDays'] as int),
    );

    final totalHalfDays = employeeSummaries.fold<int>(
      0,
      (sum, summary) => sum + (summary['stats']['halfDays'] as int),
    );

    final totalAbsentDays = employeeSummaries.fold<int>(
      0,
      (sum, summary) => sum + (summary['stats']['absentDays'] as int),
    );

    final totalPayment = employeeSummaries.fold<double>(
      0,
      (sum, summary) => sum + (summary['stats']['totalPayment'] as double),
    );

    return {
      'fullDays': totalFullDays,
      'halfDays': totalHalfDays,
      'absentDays': totalAbsentDays,
      'totalWorkDays': totalFullDays + (totalHalfDays / 2),
      'totalPayment': totalPayment,
    };
  }

  /// Hata durumunda boş sonuç döndürür
  Map<String, dynamic> _getEmptyResult(
    ReportPeriod period,
    DateTime? referenceDate,
    DateTime? customStart,
    DateTime? customEnd,
  ) {
    return {
      'periodRange': PeriodCalculator.calculate(
        period,
        referenceDate: referenceDate,
        customStart: customStart,
        customEnd: customEnd,
      ),
      'employees': <Employee>[],
      'employeeSummaries': <Map<String, dynamic>>[],
      'totals': {
        'fullDays': 0,
        'halfDays': 0,
        'absentDays': 0,
        'totalWorkDays': 0.0,
        'totalPayment': 0.0,
      },
    };
  }
}
