import 'package:flutter/foundation.dart';
import '../../../models/attendance.dart' as attendance;
import '../../../models/employee.dart';
import '../../../models/payment.dart';
import '../../../services/attendance_service.dart';
import '../../../services/payment_service.dart';
import '../../../core/di/service_locator.dart';
import '../models/period_range.dart';
import 'daily_status_calculator.dart';

/// Çalışan devam özeti hesaplama sınıfı
class AttendanceSummaryCalculator {
  final AttendanceService _attendanceService;
  final PaymentService _paymentService;

  AttendanceSummaryCalculator({
    AttendanceService? attendanceService,
    PaymentService? paymentService,
  }) : _attendanceService = attendanceService ?? getIt<AttendanceService>(),
       _paymentService = paymentService ?? getIt<PaymentService>();

  /// Çalışan için dönemsel devam özetini hesaplar
  Future<Map<String, dynamic>> calculate(
    Employee employee,
    PeriodRange periodRange,
  ) async {
    try {
      // Giriş tarihinden sonraki kayıtları kontrol et
      final effectiveStartDate =
          employee.startDate.isAfter(periodRange.startDate)
          ? employee.startDate
          : periodRange.startDate;

      // Dönem içindeki devam kayıtlarını al
      final attendanceRecords = await _attendanceService.getAttendanceBetween(
        effectiveStartDate,
        periodRange.endDate,
        workerId: employee.id,
      );

      // Günlük durumları hesapla
      final dailyStatus = DailyStatusCalculator.calculate(
        startDate: effectiveStartDate,
        endDate: periodRange.endDate,
        attendanceRecords: attendanceRecords,
        workerId: employee.id,
      );

      // Durum sayılarını hesapla
      final statusCounts = DailyStatusCalculator.countStatuses(dailyStatus);

      // Dönem içindeki ödemeleri al
      final payments = await _getPaymentsForPeriod(employee.id, periodRange);

      // Toplam ödeme miktarı
      final totalAmount = _calculateTotalPayment(payments);

      return {
        'employee': employee,
        'periodRange': periodRange,
        'stats': {
          'fullDays': statusCounts['fullDays'],
          'halfDays': statusCounts['halfDays'],
          'absentDays': statusCounts['absentDays'],
          'totalWorkDays':
              statusCounts['fullDays']! + (statusCounts['halfDays']! / 2),
          'totalPayment': totalAmount,
          'attendances': attendanceRecords,
        },
        'dailyStatus': dailyStatus,
        'payments': payments,
      };
    } catch (e, stackTrace) {
      debugPrint('AttendanceSummaryCalculator.calculate hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      return _getEmptyResult(employee, periodRange);
    }
  }

  /// Dönem içindeki ödemeleri getirir
  Future<List<Payment>> _getPaymentsForPeriod(
    int employeeId,
    PeriodRange periodRange,
  ) async {
    final payments = await _paymentService.getPaymentsByWorkerId(employeeId);
    return payments
        .where(
          (payment) =>
              !payment.paymentDate.isBefore(periodRange.startDate) &&
              !payment.paymentDate.isAfter(periodRange.endDate),
        )
        .toList();
  }

  /// Toplam ödeme tutarını hesaplar
  double _calculateTotalPayment(List<Payment> payments) {
    return payments.fold<double>(0, (sum, payment) => sum + payment.amount);
  }

  /// Hata durumunda boş sonuç döndürür
  Map<String, dynamic> _getEmptyResult(
    Employee employee,
    PeriodRange periodRange,
  ) {
    return {
      'employee': employee,
      'periodRange': periodRange,
      'stats': {
        'fullDays': 0,
        'halfDays': 0,
        'absentDays': 0,
        'totalWorkDays': 0.0,
        'totalPayment': 0.0,
        'attendances': <attendance.Attendance>[],
      },
      'dailyStatus': <DateTime, attendance.AttendanceStatus>{},
      'payments': [],
    };
  }
}
