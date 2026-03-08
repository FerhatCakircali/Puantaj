import '../../models/employee.dart';
import '../../core/error_handling/error_handler_mixin.dart';
import 'models/period_range.dart';
import 'calculators/period_calculator.dart';
import 'calculators/attendance_summary_calculator.dart';
import 'aggregators/period_summary_aggregator.dart';

export 'models/period_range.dart';

/// Rapor servisi - koordinatör
///
/// Dönemsel raporları ve çalışan özetlerini yönetir.
/// Calculator ve aggregator sınıflarını koordine eder.
class ReportService with ErrorHandlerMixin {
  final AttendanceSummaryCalculator _summaryCalculator;
  final PeriodSummaryAggregator _summaryAggregator;

  ReportService({
    AttendanceSummaryCalculator? summaryCalculator,
    PeriodSummaryAggregator? summaryAggregator,
  }) : _summaryCalculator = summaryCalculator ?? AttendanceSummaryCalculator(),
       _summaryAggregator = summaryAggregator ?? PeriodSummaryAggregator();

  /// Dönemsel tarih aralığını hesaplar
  PeriodRange calculatePeriodRange(
    ReportPeriod period, {
    DateTime? referenceDate,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    return PeriodCalculator.calculate(
      period,
      referenceDate: referenceDate,
      customStart: customStart,
      customEnd: customEnd,
    );
  }

  /// Çalışan için dönemsel devam özetini getirir
  Future<Map<String, dynamic>> getEmployeeAttendanceSummary(
    Employee employee,
    PeriodRange periodRange,
  ) async {
    return handleError(
      () async => await _summaryCalculator.calculate(employee, periodRange),
      {},
      context: 'ReportService.getEmployeeAttendanceSummary',
    );
  }

  /// Tüm çalışanlar için dönemsel özet rapor oluşturur
  Future<Map<String, dynamic>> getPeriodSummaryReport(
    ReportPeriod period, {
    DateTime? referenceDate,
    DateTime? customStart,
    DateTime? customEnd,
    int? specificEmployeeId,
  }) async {
    return handleError(
      () async => await _summaryAggregator.aggregate(
        period,
        referenceDate: referenceDate,
        customStart: customStart,
        customEnd: customEnd,
        specificEmployeeId: specificEmployeeId,
      ),
      {},
      context: 'ReportService.getPeriodSummaryReport',
    );
  }
}
