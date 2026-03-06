import 'package:flutter/material.dart';

import '../../widgets/screen_widgets/index.dart';

/// Tarih seçimi operasyonları
class ReportControllerDateOperations {
  /// Tarih aralığı seç
  static Future<void> selectDateRange({
    required BuildContext context,
    required State state,
    required DateTime currentStartDate,
    required DateTime currentEndDate,
    required void Function(DateTime, DateTime) onUpdate,
    required Future<void> Function() onLoadData,
  }) async {
    if (!state.mounted) return;

    debugPrint('ReportControllerMixin: Tarih aralığı seçiliyor');

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: currentStartDate,
        end: currentEndDate,
      ),
    );

    if (pickedRange != null && state.mounted) {
      onUpdate(pickedRange.start, pickedRange.end);
      await onLoadData();

      debugPrint('ReportControllerMixin: Tarih aralığı güncellendi');
    }
  }

  /// Özel tarih seç
  static Future<void> selectCustomDate({
    required BuildContext context,
    required State state,
    required bool isStartDate,
    required DateTime currentCustomStartDate,
    required DateTime currentCustomEndDate,
    required void Function(DateTime, DateTime) onUpdate,
  }) async {
    if (!state.mounted) return;

    final DateTime initialDate = isStartDate
        ? currentCustomStartDate
        : currentCustomEndDate;

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null && state.mounted) {
      DateTime newStart = currentCustomStartDate;
      DateTime newEnd = currentCustomEndDate;

      if (isStartDate) {
        newStart = selectedDate;
        if (newStart.isAfter(newEnd)) {
          newEnd = newStart;
        }
      } else {
        newEnd = selectedDate;
        if (newEnd.isBefore(newStart)) {
          newStart = newEnd;
        }
      }

      onUpdate(newStart, newEnd);

      debugPrint('ReportControllerMixin: Özel tarih güncellendi');
    }
  }

  /// Dönem tarihlerini güncelle
  static Map<String, DateTime> updatePeriodDates({
    required State state,
    required ReportPeriod period,
    required DateTime currentCustomStartDate,
    required DateTime currentCustomEndDate,
  }) {
    if (!state.mounted) {
      return {'start': currentCustomStartDate, 'end': currentCustomEndDate};
    }

    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (period) {
      case ReportPeriod.daily:
        // Bugün
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case ReportPeriod.weekly:
        // Son 7 gün
        start = now.subtract(const Duration(days: 7));
        break;
      case ReportPeriod.monthly:
        // Bu ayın başından bugüne
        start = DateTime(now.year, now.month, 1);
        break;
      case ReportPeriod.quarterly:
        // Son 3 ay (bu ay dahil)
        int startMonth = now.month - 2;
        int startYear = now.year;
        if (startMonth <= 0) {
          startMonth += 12;
          startYear -= 1;
        }
        start = DateTime(startYear, startMonth, 1);
        break;
      case ReportPeriod.yearly:
        // Bu yılın başından bugüne
        start = DateTime(now.year, 1, 1);
        break;
      case ReportPeriod.custom:
        start = currentCustomStartDate;
        end = currentCustomEndDate;
        break;
    }

    debugPrint('ReportControllerMixin: Dönem tarihleri güncellendi');
    debugPrint('Başlangıç: $start');
    debugPrint('Bitiş: $end');

    return {'start': start, 'end': end};
  }
}
