import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance.dart' as attendance;
import '../models/payment.dart';
import '../models/employee.dart';
import 'attendance_service.dart';
import 'payment_service.dart';
import 'worker_service.dart';

enum ReportPeriod { daily, weekly, monthly, quarterly, yearly, custom }

class PeriodRange {
  final DateTime startDate;
  final DateTime endDate;
  final String title;

  PeriodRange({
    required this.startDate,
    required this.endDate,
    required this.title,
  });
}

class ReportService {
  static final ReportService _instance = ReportService._internal();

  final AttendanceService _attendanceService = AttendanceService();
  final PaymentService _paymentService = PaymentService();
  final WorkerService _workerService = WorkerService();

  factory ReportService() {
    return _instance;
  }

  ReportService._internal();

  // Dönemsel tarih aralığı hesaplama
  PeriodRange calculatePeriodRange(
    ReportPeriod period, {
    DateTime? referenceDate,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final now = referenceDate ?? DateTime.now();

    switch (period) {
      case ReportPeriod.daily:
        return PeriodRange(
          startDate: DateTime(now.year, now.month, now.day),
          endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
          title: 'Günlük Rapor (${DateFormat('dd/MM/yyyy').format(now)})',
        );

      case ReportPeriod.weekly:
        // Bugünden 7 gün öncesini al
        final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        final startDate = endDate.subtract(const Duration(days: 6));

        return PeriodRange(
          startDate: startDate,
          endDate: endDate,
          title:
              'Haftalık Rapor (${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)})',
        );

      case ReportPeriod.monthly:
        // Bugünden 30 gün öncesini al
        final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        final startDate = endDate.subtract(const Duration(days: 29));

        return PeriodRange(
          startDate: startDate,
          endDate: endDate,
          title:
              'Aylık Rapor (${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)})',
        );

      case ReportPeriod.quarterly:
        final currentQuarter = ((now.month - 1) ~/ 3) + 1;
        final startMonth = (currentQuarter - 1) * 3 + 1;

        final startDate = DateTime(now.year, startMonth, 1);

        // Çeyreğin son ayını hesapla
        final endMonth = startMonth + 2; // 3 aylık dönem
        final year = now.year + (endMonth > 12 ? 1 : 0);
        final normalizedEndMonth = endMonth > 12 ? endMonth - 12 : endMonth;

        // Ayın son gününü bul
        final lastDayOfEndMonth = DateTime(year, normalizedEndMonth + 1, 0);

        final endDate = DateTime(
          lastDayOfEndMonth.year,
          lastDayOfEndMonth.month,
          lastDayOfEndMonth.day,
          23,
          59,
          59,
        );

        // Türkçe ay isimleri - 'tr_TR' locale sorununu aşmak için
        final aylar = [
          '',
          'Ocak',
          'Şubat',
          'Mart',
          'Nisan',
          'Mayıs',
          'Haziran',
          'Temmuz',
          'Ağustos',
          'Eylül',
          'Ekim',
          'Kasım',
          'Aralık',
        ];

        return PeriodRange(
          startDate: startDate,
          endDate: endDate,
          title:
              '$currentQuarter. Çeyrek Rapor (${aylar[startDate.month]} - ${aylar[normalizedEndMonth]} ${endDate.year})',
        );

      case ReportPeriod.yearly:
        return PeriodRange(
          startDate: DateTime(now.year, 1, 1),
          endDate: DateTime(now.year, 12, 31, 23, 59, 59),
          title: 'Yıllık Rapor (${now.year})',
        );

      case ReportPeriod.custom:
        if (customStart == null || customEnd == null) {
          throw ArgumentError(
            'Özel dönem için başlangıç ve bitiş tarihleri gereklidir',
          );
        }

        return PeriodRange(
          startDate: DateTime(
            customStart.year,
            customStart.month,
            customStart.day,
          ),
          endDate: DateTime(
            customEnd.year,
            customEnd.month,
            customEnd.day,
            23,
            59,
            59,
          ),
          title:
              'Özel Dönem Raporu (${DateFormat('dd/MM/yyyy').format(customStart)} - ${DateFormat('dd/MM/yyyy').format(customEnd)})',
        );
    }
  }

  // Çalışan için dönemsel devam verilerini al
  Future<Map<String, dynamic>> getEmployeeAttendanceSummary(
    Employee employee,
    PeriodRange periodRange,
  ) async {
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

    // İstatistikler
    int fullDays = 0;
    int halfDays = 0;
    int absentDays = 0;

    // Her gün için devam durumunu hesapla
    DateTime currentDate = effectiveStartDate;
    final Map<DateTime, attendance.AttendanceStatus> dailyStatus = {};

    while (!currentDate.isAfter(periodRange.endDate)) {
      // O güne ait devam kaydı var mı kontrol et
      final record = attendanceRecords.firstWhere(
        (r) =>
            r.date.year == currentDate.year &&
            r.date.month == currentDate.month &&
            r.date.day == currentDate.day,
        orElse:
            () => attendance.Attendance(
              userId: 0,
              workerId: employee.id,
              date: currentDate,
              status: attendance.AttendanceStatus.absent,
            ),
      );

      dailyStatus[DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
          )] =
          record.status;

      switch (record.status) {
        case attendance.AttendanceStatus.fullDay:
          fullDays++;
          break;
        case attendance.AttendanceStatus.halfDay:
          halfDays++;
          break;
        case attendance.AttendanceStatus.absent:
          absentDays++;
          break;
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Dönem içindeki ödemeleri al
    final payments = await _paymentService.getPaymentsByWorkerId(employee.id);
    final periodPayments =
        payments
            .where(
              (payment) =>
                  !payment.paymentDate.isBefore(periodRange.startDate) &&
                  !payment.paymentDate.isAfter(periodRange.endDate),
            )
            .toList();

    // Toplam ödeme miktarı
    final totalAmount = periodPayments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );

    return {
      'employee': employee,
      'periodRange': periodRange,
      'stats': {
        'fullDays': fullDays,
        'halfDays': halfDays,
        'absentDays': absentDays,
        'totalWorkDays': fullDays + (halfDays / 2),
        'totalPayment': totalAmount,
        'attendances': attendanceRecords,
      },
      'dailyStatus': dailyStatus,
      'payments': periodPayments,
    };
  }

  // Tüm çalışanlar için dönemsel özet
  Future<Map<String, dynamic>> getPeriodSummaryReport(
    ReportPeriod period, {
    DateTime? referenceDate,
    DateTime? customStart,
    DateTime? customEnd,
    int? specificEmployeeId,
  }) async {
    final periodRange = calculatePeriodRange(
      period,
      referenceDate: referenceDate,
      customStart: customStart,
      customEnd: customEnd,
    );

    List<Employee> employees;
    if (specificEmployeeId != null) {
      // Tek bir çalışan için rapor
      final allEmployees = await _workerService.getEmployees();
      employees =
          allEmployees.where((e) => e.id == specificEmployeeId).toList();
    } else {
      // Tüm çalışanlar için rapor
      employees = await _workerService.getEmployees();
    }

    // Her çalışan için dönemsel özet topla
    final employeeSummaries = <Map<String, dynamic>>[];

    for (final employee in employees) {
      final summary = await getEmployeeAttendanceSummary(employee, periodRange);
      employeeSummaries.add(summary);
    }

    // Genel totaller
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
      'periodRange': periodRange,
      'employees': employees,
      'employeeSummaries': employeeSummaries,
      'totals': {
        'fullDays': totalFullDays,
        'halfDays': totalHalfDays,
        'absentDays': totalAbsentDays,
        'totalWorkDays': totalFullDays + (totalHalfDays / 2),
        'totalPayment': totalPayment,
      },
    };
  }
}
