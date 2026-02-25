import 'package:flutter/material.dart';

import '../../widgets/screen_widgets/index.dart';

/// Tarih seçimi işlemleri mixin'i
mixin ReportControllerDateMixin<T extends StatefulWidget> on State<T> {
  DateTime get startDate;
  DateTime get endDate;
  DateTime get customStartDate;
  DateTime get customEndDate;

  set startDate(DateTime value);
  set endDate(DateTime value);
  set customStartDate(DateTime value);
  set customEndDate(DateTime value);

  Future<void> loadData();

  /// Tarih aralığı seç
  Future<void> selectDateRange(BuildContext context) async {
    if (!mounted) return;

    debugPrint('📅 ReportControllerMixin: Tarih aralığı seçiliyor');

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
    );

    if (pickedRange != null && mounted) {
      setState(() {
        startDate = pickedRange.start;
        endDate = pickedRange.end;
      });
      await loadData();

      debugPrint('✅ ReportControllerMixin: Tarih aralığı güncellendi');
    }
  }

  /// Özel tarih seç
  Future<void> selectCustomDate(bool isStartDate) async {
    if (!mounted) return;

    final DateTime initialDate = isStartDate ? customStartDate : customEndDate;

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null && mounted) {
      setState(() {
        if (isStartDate) {
          customStartDate = selectedDate;
          if (customStartDate.isAfter(customEndDate)) {
            customEndDate = customStartDate;
          }
        } else {
          customEndDate = selectedDate;
          if (customEndDate.isBefore(customStartDate)) {
            customStartDate = customEndDate;
          }
        }
      });

      debugPrint('✅ ReportControllerMixin: Özel tarih güncellendi');
    }
  }

  /// Dönem tarihlerini güncelle
  void updatePeriodDates(ReportPeriod period) {
    if (!mounted) return;

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
        start = customStartDate;
        end = customEndDate;
        break;
    }

    setState(() {
      customStartDate = start;
      customEndDate = end;
    });

    debugPrint('✅ ReportControllerMixin: Dönem tarihleri güncellendi');
  }
}
