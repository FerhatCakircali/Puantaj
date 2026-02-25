import 'package:flutter/material.dart';

/// Worker attendance helper metodları
class WorkerAttendanceHelpers {
  /// Gün bilgisini çıkar
  static String extractDaysInfo(String notes) {
    final match = RegExp(r'(\d+)\s*gün').firstMatch(notes);
    if (match != null) {
      return '${match.group(1)} gün için ödeme';
    }
    return '';
  }

  /// Tam gün sayısını çıkar
  static int extractFullDays(String notes) {
    final match = RegExp(r'(\d+)\s*Tam Gün').firstMatch(notes);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  /// Yarım gün sayısını çıkar
  static int extractHalfDays(String notes) {
    final match = RegExp(r'(\d+)\s*Yarım Gün').firstMatch(notes);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  /// Para formatını Türk formatına çevir
  static String formatCurrencySimple(double amount) {
    final intAmount = amount.round();
    final amountStr = intAmount.toString();

    final buffer = StringBuffer();
    var count = 0;

    for (var i = amountStr.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(amountStr[i]);
      count++;
    }

    return buffer.toString().split('').reversed.join('');
  }

  /// Durum rengi
  static Color getStatusColor(String status) {
    switch (status) {
      case 'fullDay':
        return Colors.green;
      case 'halfDay':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Durum metni
  static String getStatusText(String status) {
    switch (status) {
      case 'fullDay':
        return 'Tam Gün';
      case 'halfDay':
        return 'Yarım Gün';
      case 'absent':
        return 'Gelmedi';
      default:
        return status;
    }
  }

  /// Durum ikonu
  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'fullDay':
        return Icons.check_circle;
      case 'halfDay':
        return Icons.schedule;
      case 'absent':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
