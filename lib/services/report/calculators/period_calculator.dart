import 'package:intl/intl.dart';
import '../models/period_range.dart';
import '../constants/turkish_months.dart';

/// Dönem aralığı hesaplama sınıfı
class PeriodCalculator {
  /// Dönemsel tarih aralığını hesaplar
  static PeriodRange calculate(
    ReportPeriod period, {
    DateTime? referenceDate,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final now = referenceDate ?? DateTime.now();

    switch (period) {
      case ReportPeriod.daily:
        return _calculateDaily(now);
      case ReportPeriod.weekly:
        return _calculateWeekly(now);
      case ReportPeriod.monthly:
        return _calculateMonthly(now);
      case ReportPeriod.quarterly:
        return _calculateQuarterly(now);
      case ReportPeriod.yearly:
        return _calculateYearly(now);
      case ReportPeriod.custom:
        return _calculateCustom(customStart, customEnd);
    }
  }

  static PeriodRange _calculateDaily(DateTime now) {
    return PeriodRange(
      startDate: DateTime(now.year, now.month, now.day),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
      title: 'Günlük Rapor (${DateFormat('dd/MM/yyyy').format(now)})',
    );
  }

  static PeriodRange _calculateWeekly(DateTime now) {
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final startDate = endDate.subtract(const Duration(days: 6));

    return PeriodRange(
      startDate: startDate,
      endDate: endDate,
      title:
          'Haftalık Rapor (${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)})',
    );
  }

  static PeriodRange _calculateMonthly(DateTime now) {
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final startDate = endDate.subtract(const Duration(days: 29));

    return PeriodRange(
      startDate: startDate,
      endDate: endDate,
      title:
          'Aylık Rapor (${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)})',
    );
  }

  static PeriodRange _calculateQuarterly(DateTime now) {
    final currentQuarter = ((now.month - 1) ~/ 3) + 1;
    final startMonth = (currentQuarter - 1) * 3 + 1;

    final startDate = DateTime(now.year, startMonth, 1);

    final endMonth = startMonth + 2;
    final year = now.year + (endMonth > 12 ? 1 : 0);
    final normalizedEndMonth = endMonth > 12 ? endMonth - 12 : endMonth;

    final lastDayOfEndMonth = DateTime(year, normalizedEndMonth + 1, 0);

    final endDate = DateTime(
      lastDayOfEndMonth.year,
      lastDayOfEndMonth.month,
      lastDayOfEndMonth.day,
      23,
      59,
      59,
    );

    return PeriodRange(
      startDate: startDate,
      endDate: endDate,
      title:
          '$currentQuarter. Çeyrek Rapor (${TurkishMonths.getName(startDate.month)} - ${TurkishMonths.getName(normalizedEndMonth)} ${endDate.year})',
    );
  }

  static PeriodRange _calculateYearly(DateTime now) {
    return PeriodRange(
      startDate: DateTime(now.year, 1, 1),
      endDate: DateTime(now.year, 12, 31, 23, 59, 59),
      title: 'Yıllık Rapor (${now.year})',
    );
  }

  static PeriodRange _calculateCustom(
    DateTime? customStart,
    DateTime? customEnd,
  ) {
    if (customStart == null || customEnd == null) {
      throw ArgumentError(
        'Özel dönem için başlangıç ve bitiş tarihleri gereklidir',
      );
    }

    return PeriodRange(
      startDate: DateTime(customStart.year, customStart.month, customStart.day),
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
