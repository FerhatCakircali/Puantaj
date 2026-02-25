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

    debugPrint('📅 ReportControllerMixin: Tarih aralığı seçiliyor');

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

      debugPrint('✅ ReportControllerMixin: Tarih aralığı güncellendi');
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

      debugPrint('✅ ReportControllerMixin: Özel tarih güncellendi');
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
        start = now;
        break;
      case ReportPeriod.weekly:
        start = now.subtract(const Duration(days: 7));
        break;
      case ReportPeriod.monthly:
        start = now.subtract(const Duration(days: 30));
        break;
      case ReportPeriod.quarterly:
        start = now.subtract(const Duration(days: 90));
        break;
      case ReportPeriod.yearly:
        start = now.subtract(const Duration(days: 365));
        break;
      case ReportPeriod.custom:
        start = currentCustomStartDate;
        end = currentCustomEndDate;
        break;
    }

    debugPrint('✅ ReportControllerMixin: Dönem tarihleri güncellendi');

    return {'start': start, 'end': end};
  }
}
