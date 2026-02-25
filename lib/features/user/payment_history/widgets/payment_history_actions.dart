import 'package:flutter/material.dart';
import '../../../../screens/constants/colors.dart';

/// Ödeme geçmişi ekranı için yardımcı aksiyonlar
class PaymentHistoryActions {
  /// Başarı mesajı gösterir
  static void showSuccessMessage(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryIndigo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  /// Hata mesajı gösterir
  static void showErrorMessage(BuildContext context, String error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hata: $error'),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  /// Tarih aralığı seçici gösterir
  static Future<DateTimeRange?> selectDateRange(
    BuildContext context,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
    );
  }
}
