import 'package:intl/intl.dart';

/// Hatırlatıcı tarih formatlama yardımcı sınıfı
///
/// Tarihleri kullanıcı dostu formatlara çevirir.
class ReminderDateFormatter {
  /// Tarihi kısa formatta döndürür (Bugün, Yarın, veya tarih)
  static String formatShortDate(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isTomorrow =
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day + 1;

    final timeText = DateFormat('HH:mm', 'tr_TR').format(date);

    if (isToday) {
      return 'Bugün $timeText';
    } else if (isTomorrow) {
      return 'Yarın $timeText';
    } else {
      return '${DateFormat('dd MMM', 'tr_TR').format(date)} $timeText';
    }
  }

  /// Tarihin bugün olup olmadığını kontrol eder
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Tarihi uzun formatta döndürür
  static String formatLongDate(DateTime date) {
    return DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(date);
  }

  /// Saati formatlar
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm', 'tr_TR').format(date);
  }
}
