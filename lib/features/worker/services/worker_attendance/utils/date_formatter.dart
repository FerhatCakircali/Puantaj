/// Tarih formatlama yardımcı sınıfı
class DateFormatter {
  /// DateTime'ı YYYY-MM-DD formatına çevirir
  static String format(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Bugünün tarihini formatlar
  static String today() {
    return format(DateTime.now());
  }

  /// Tarih aralığını formatlar
  static Map<String, String> formatRange(DateTime start, DateTime end) {
    return {'start': format(start), 'end': format(end)};
  }
}
