import 'package:flutter/foundation.dart';
import '../utils/date_formatter.dart';

/// Aylık istatistik hesaplama sınıfı
class MonthlyStatsCalculator {
  /// Yevmiye kayıtlarından tarih listelerini çıkarır
  static Map<String, List<String>> extractDatesByStatus(
    List<Map<String, dynamic>> records,
  ) {
    final fullDayDates = <String>[];
    final halfDayDates = <String>[];

    for (final record in records) {
      final date = record['date'] as String;
      final status = record['status'] as String;

      if (status == 'fullDay') {
        fullDayDates.add(date);
      } else if (status == 'halfDay') {
        halfDayDates.add(date);
      }
    }

    return {'fullDay': fullDayDates, 'halfDay': halfDayDates};
  }

  /// Devamsızlık tarihlerini hesaplar
  static List<String> calculateAbsentDates({
    required DateTime monthStart,
    required DateTime monthEnd,
    required Set<String> workedDates,
    DateTime? workerStartDate,
  }) {
    final absentDates = <String>[];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = monthEnd.isAfter(today) ? today : monthEnd;

    var startDate = monthStart;
    if (workerStartDate != null) {
      final workerStartDateOnly = DateTime(
        workerStartDate.year,
        workerStartDate.month,
        workerStartDate.day,
      );
      if (workerStartDateOnly.isAfter(startDate)) {
        startDate = workerStartDateOnly;
      }
    }

    var date = startDate;
    while (date.isBefore(endDate) || date.isAtSameMomentAs(endDate)) {
      final dateStr = DateFormatter.format(date);
      if (!workedDates.contains(dateStr)) {
        absentDates.add(dateStr);
      }
      date = date.add(const Duration(days: 1));
    }

    return absentDates;
  }

  /// Detaylı aylık istatistikleri hesaplar
  static Map<String, dynamic> calculateDetailedStats({
    required List<Map<String, dynamic>> attendanceRecords,
    required double totalAmount,
    required DateTime monthStart,
    required DateTime monthEnd,
    DateTime? workerStartDate,
  }) {
    try {
      final datesByStatus = extractDatesByStatus(attendanceRecords);
      final fullDayDates = datesByStatus['fullDay']!;
      final halfDayDates = datesByStatus['halfDay']!;

      final workedDates = <String>{};
      for (final record in attendanceRecords) {
        workedDates.add(record['date'] as String);
      }

      final absentDates = calculateAbsentDates(
        monthStart: monthStart,
        monthEnd: monthEnd,
        workedDates: workedDates,
        workerStartDate: workerStartDate,
      );

      return {
        'total_full_days': fullDayDates.length,
        'total_half_days': halfDayDates.length,
        'total_absent_days': absentDates.length,
        'total_amount': totalAmount,
        'full_day_dates': fullDayDates,
        'half_day_dates': halfDayDates,
        'absent_dates': absentDates,
      };
    } catch (e) {
      debugPrint('calculateDetailedStats hata: $e');
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
}
