import 'package:flutter/foundation.dart';
import '../../../../models/attendance.dart';
import 'repositories/attendance_repository.dart';
import 'repositories/payment_repository.dart';
import 'repositories/worker_repository.dart';
import 'calculators/monthly_stats_calculator.dart';
import 'utils/date_formatter.dart';

/// Çalışan yevmiye servisi - koordinatör
///
/// Repository'leri ve calculator'ları koordine eder.
/// SQL fonksiyonları:
/// - check_worker_today_attendance_status: Bugünün durumunu kontrol et
/// - get_worker_attendance_history: Geçmiş kayıtları getir
/// - get_worker_monthly_stats: Aylık istatistikler
/// - get_worker_total_payments: Toplam kazanç
class WorkerAttendanceService {
  final AttendanceRepository _attendanceRepo = AttendanceRepository();
  final PaymentRepository _paymentRepo = PaymentRepository();
  final WorkerRepository _workerRepo = WorkerRepository();

  /// Bugün için yevmiye durumunu kontrol eder
  Future<Map<String, dynamic>?> checkTodayStatus(int workerId) async {
    return await _attendanceRepo.checkTodayStatus(workerId);
  }

  /// Yevmiye talebi gönderir
  Future<bool> submitAttendanceRequest({
    required int workerId,
    int? userId,
    required DateTime date,
    required AttendanceStatus status,
    String? workerName,
  }) async {
    try {
      final formattedDate = DateFormatter.format(date);

      // Çalışanın yöneticisini ve adını al
      final workerInfo = await _workerRepo.getWorkerInfo(workerId);
      if (workerInfo == null) {
        debugPrint('Çalışan bilgisi alınamadı');
        return false;
      }

      final managerId = workerInfo['managerId'] as int;
      final effectiveWorkerName =
          workerName ?? (workerInfo['workerName'] as String);

      debugPrint('Çalışan ID: $workerId');
      debugPrint('Yönetici ID: $managerId');
      debugPrint('Çalışan Adı: $effectiveWorkerName');

      return await _attendanceRepo.submitRequest(
        workerId: workerId,
        managerId: managerId,
        date: formattedDate,
        status: status,
      );
    } catch (e) {
      debugPrint('submitAttendanceRequest hata: $e');
      return false;
    }
  }

  /// Geçmiş yevmiye kayıtlarını getirir
  Future<List<Map<String, dynamic>>> getAttendanceHistory({
    required int workerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _attendanceRepo.getHistory(
      workerId: workerId,
      startDate: DateFormatter.format(startDate),
      endDate: DateFormatter.format(endDate),
    );
  }

  /// Aylık istatistikleri getirir
  Future<Map<String, dynamic>?> getMonthlyStats({
    required int workerId,
    required DateTime monthStart,
    required DateTime monthEnd,
  }) async {
    return await _attendanceRepo.getMonthlyStats(
      workerId: workerId,
      monthStart: DateFormatter.format(monthStart),
      monthEnd: DateFormatter.format(monthEnd),
    );
  }

  /// Aylık detaylı istatistikleri getirir (tarihlerle birlikte)
  Future<Map<String, dynamic>> getMonthlyStatsWithDates({
    required int workerId,
    required DateTime monthStart,
    required DateTime monthEnd,
  }) async {
    try {
      // Çalışanın başlangıç tarihini al
      final workerStartDate = await _workerRepo.getWorkerStartDate(workerId);

      // Yevmiye kayıtlarını al
      final attendanceRecords = await _attendanceRepo.getMonthlyRecords(
        workerId: workerId,
        monthStart: DateFormatter.format(monthStart),
        monthEnd: DateFormatter.format(monthEnd),
      );

      // Ödeme tutarını al
      final totalAmount = await _paymentRepo.getTotalAmountForPeriod(
        workerId: workerId,
        startDate: DateFormatter.format(monthStart),
        endDate: DateFormatter.format(monthEnd),
      );

      // İstatistikleri hesapla
      return MonthlyStatsCalculator.calculateDetailedStats(
        attendanceRecords: attendanceRecords,
        totalAmount: totalAmount,
        monthStart: monthStart,
        monthEnd: monthEnd,
        workerStartDate: workerStartDate,
      );
    } catch (e) {
      debugPrint('getMonthlyStatsWithDates hata: $e');
      return {
        'total_full_days': 0,
        'total_half_days': 0,
        'total_absent_days': 0,
        'total_amount': 0.0,
        'full_day_dates': <String>[],
        'half_day_dates': <String>[],
        'absent_dates': <String>[],
      };
    }
  }

  /// Toplam kazancı getirir
  Future<double> getTotalPayments(int workerId) async {
    return await _paymentRepo.getTotalPayments(workerId);
  }

  /// Reddedilen talebi siler
  Future<bool> deleteRejectedRequest({
    required int workerId,
    required DateTime date,
  }) async {
    return await _attendanceRepo.deleteRejectedRequest(
      workerId: workerId,
      date: DateFormatter.format(date),
    );
  }

  /// Ödeme geçmişini getirir
  Future<List<Map<String, dynamic>>> getPaymentHistory({
    required int workerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _paymentRepo.getHistory(
      workerId: workerId,
      startDate: DateFormatter.format(startDate),
      endDate: DateFormatter.format(endDate),
    );
  }

  /// Ödeme detaylarını getirir
  Future<Map<String, dynamic>?> getPaymentDetails(int paymentId) async {
    return await _paymentRepo.getDetails(paymentId);
  }
}
