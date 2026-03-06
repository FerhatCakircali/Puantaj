/// DateFormatter utility sınıfı - Uygulama genelinde tutarlı tarih formatlama.
///
/// Bu utility, servis dosyalarındaki kod tekrarını ortadan kaldırmak için
/// standartlaştırılmış tarih formatlama metodları sağlar. Tüm tarihler
/// veritabanı işlemleri için ISO 8601 formatı (YYYY-MM-DD) kullanır.
///
/// **Önemli:** Tüm tarihler Türkiye saat diliminde (Europe/Istanbul, UTC+3) işlenir.
/// Bu, Türk iş operasyonları için uygulama genelinde tutarlılık sağlar.
///
/// Saat Dilimi: Europe/Istanbul (UTC+3)
class DateFormatter {
  DateFormatter._();

  /// Türkiye saat dilimi tanımlayıcısı
  static const String turkeyTimezone = 'Europe/Istanbul';

  /// DateTime'ı ISO 8601 tarih string formatına (YYYY-MM-DD) dönüştürür.
  ///
  /// Bu format tüm veritabanı işlemleri ve API çağrıları için kullanılır.
  /// Tarih, Türkiye yerel saati (Europe/Istanbul, UTC+3) olarak işlenir.
  ///
  /// Örnek:
  /// ```dart
  /// final date = DateTime(2024, 3, 5);
  /// final formatted = DateFormatter.toIso8601Date(date);
  /// print(formatted); // "2024-03-05"
  /// ```
  ///
  /// Not: Bu metod, tarih bileşenlerini saat dilimi dönüşümü olmadan doğrudan
  /// formatlar ve giriş DateTime'ın zaten Türkiye yerel saatinde olduğunu varsayar.
  static String toIso8601Date(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// ISO 8601 tarih string'ini (YYYY-MM-DD) DateTime'a parse eder.
  ///
  /// Döndürülen DateTime, Türkiye yerel saatindedir (Europe/Istanbul, UTC+3).
  ///
  /// Geçersiz ISO 8601 formatı durumunda [FormatException] fırlatır.
  ///
  /// Örnek:
  /// ```dart
  /// final date = DateFormatter.fromIso8601Date("2024-03-05");
  /// print(date); // 2024-03-05 00:00:00.000
  /// ```
  ///
  /// Not: DateTime.parse() yerel saat diliminde bir DateTime döndürür,
  /// bu uygulama için Türkiye saat dilimi (UTC+3) olmalıdır.
  static DateTime fromIso8601Date(String dateString) {
    return DateTime.parse(dateString);
  }

  /// DateTime'ı görüntüleme dostu Türk tarih formatına dönüştürür.
  ///
  /// Format: "DD.MM.YYYY" (Türk standardı)
  /// Saat Dilimi: Europe/Istanbul (UTC+3)
  ///
  /// Örnek:
  /// ```dart
  /// final date = DateTime(2024, 3, 5);
  /// final formatted = DateFormatter.toDisplayDate(date);
  /// print(formatted); // "05.03.2024"
  /// ```
  static String toDisplayDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// DateTime'ı kısa Türk tarih formatına dönüştürür.
  ///
  /// Format: "DD.MM.YY" (Türk standardı, kısa yıl)
  /// Saat Dilimi: Europe/Istanbul (UTC+3)
  ///
  /// Örnek:
  /// ```dart
  /// final date = DateTime(2024, 3, 5);
  /// final formatted = DateFormatter.toShortDate(date);
  /// print(formatted); // "05.03.24"
  /// ```
  static String toShortDate(DateTime date) {
    final yearShort = date.year.toString().substring(2);
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.$yearShort';
  }
}
