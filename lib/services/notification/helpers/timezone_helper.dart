import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

/// Timezone dönüşüm ve yönetim helper'ı
/// Bu sınıf timezone ile ilgili tüm dönüşüm ve hesaplama işlemlerini
/// merkezi bir noktada toplar. Single Responsibility prensibi gereği
/// sadece timezone işlemlerinden sorumludur.
/// Kullanım:
/// ```dart
/// final helper = TimezoneHelper();
/// final istanbulTime = helper.toIstanbulTime(DateTime.now());
/// final tzDateTime = helper.toTZDateTime(DateTime.now());
/// ```
class TimezoneHelper {
  /// Varsayılan timezone: Europe/Istanbul
  static const String defaultTimezone = 'Europe/Istanbul';

  /// Fallback timezone: UTC
  static const String fallbackTimezone = 'UTC';

  /// Singleton instance
  static final TimezoneHelper _instance = TimezoneHelper._internal();

  /// Factory constructor - singleton pattern
  factory TimezoneHelper() => _instance;

  TimezoneHelper._internal();

  /// Mevcut timezone location'ını döndürür
  /// Önce Istanbul timezone'unu dener, başarısız olursa UTC kullanır.
  tz.Location get currentLocation {
    try {
      return tz.getLocation(defaultTimezone);
    } catch (e) {
      debugPrint('Istanbul timezone alınamadı, UTC kullanılıyor: $e');
      return tz.getLocation(fallbackTimezone);
    }
  }

  /// DateTime'ı TZDateTime'a dönüştürür (Istanbul timezone)
  /// [dateTime] - Dönüştürülecek DateTime
  /// Returns: Istanbul timezone'unda TZDateTime
  /// Örnek:
  /// ```dart
  /// final now = DateTime.now();
  /// final tzNow = helper.toTZDateTime(now);
  /// ```
  tz.TZDateTime toTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, currentLocation);
  }

  /// DateTime'ı belirtilen timezone'da TZDateTime'a dönüştürür
  /// [dateTime] - Dönüştürülecek DateTime
  /// [timezoneName] - Hedef timezone adı (örn: 'Europe/Istanbul')
  /// Returns: Belirtilen timezone'da TZDateTime
  /// Örnek:
  /// ```dart
  /// final now = DateTime.now();
  /// final londonTime = helper.toTZDateTimeWithTimezone(now, 'Europe/London');
  /// ```
  tz.TZDateTime toTZDateTimeWithTimezone(
    DateTime dateTime,
    String timezoneName,
  ) {
    try {
      final location = tz.getLocation(timezoneName);
      return tz.TZDateTime.from(dateTime, location);
    } catch (e) {
      debugPrint(
        '⚠️ Timezone "$timezoneName" bulunamadı, varsayılan kullanılıyor: $e',
      );
      return toTZDateTime(dateTime);
    }
  }

  /// Şu anki zamanı Istanbul timezone'unda TZDateTime olarak döndürür
  /// Returns: Şu anki zaman (Istanbul timezone)
  /// Örnek:
  /// ```dart
  /// final now = helper.nowInIstanbul();
  /// ```
  tz.TZDateTime nowInIstanbul() {
    return tz.TZDateTime.now(currentLocation);
  }

  /// Belirtilen saat ve dakikada bugün için TZDateTime oluşturur
  /// [hour] - Saat (0-23)
  /// [minute] - Dakika (0-59)
  /// Returns: Bugün belirtilen saatte TZDateTime
  /// Örnek:
  /// ```dart
  /// // Bugün saat 17:00 için TZDateTime
  /// final reminderTime = helper.todayAt(17, 0);
  /// ```
  tz.TZDateTime todayAt(int hour, int minute) {
    final now = nowInIstanbul();
    return tz.TZDateTime(
      currentLocation,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
  }

  /// Belirtilen saat ve dakikada yarın için TZDateTime oluşturur
  /// [hour] - Saat (0-23)
  /// [minute] - Dakika (0-59)
  /// Returns: Yarın belirtilen saatte TZDateTime
  /// Örnek:
  /// ```dart
  /// // Yarın saat 09:00 için TZDateTime
  /// final tomorrowMorning = helper.tomorrowAt(9, 0);
  /// ```
  tz.TZDateTime tomorrowAt(int hour, int minute) {
    final tomorrow = nowInIstanbul().add(const Duration(days: 1));
    return tz.TZDateTime(
      currentLocation,
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      hour,
      minute,
    );
  }

  /// Belirtilen tarih ve saatte TZDateTime oluşturur
  /// [year] - Yıl
  /// [month] - Ay (1-12)
  /// [day] - Gün (1-31)
  /// [hour] - Saat (0-23)
  /// [minute] - Dakika (0-59)
  /// [second] - Saniye (0-59) - opsiyonel, varsayılan 0
  /// Returns: Belirtilen tarih ve saatte TZDateTime
  /// Örnek:
  /// ```dart
  /// // 2026-12-31 23:59:00
  /// final newYearEve = helper.createTZDateTime(2026, 12, 31, 23, 59);
  /// ```
  tz.TZDateTime createTZDateTime(
    int year,
    int month,
    int day,
    int hour,
    int minute, [
    int second = 0,
  ]) {
    return tz.TZDateTime(
      currentLocation,
      year,
      month,
      day,
      hour,
      minute,
      second,
    );
  }

  /// Verilen TZDateTime'ın geçmişte olup olmadığını kontrol eder
  /// [dateTime] - Kontrol edilecek TZDateTime
  /// Returns: Geçmişteyse true, değilse false
  /// Örnek:
  /// ```dart
  /// final pastTime = helper.todayAt(8, 0);
  /// if (helper.isPast(pastTime)) {
  ///   print('Bu saat geçti');
  /// }
  /// ```
  bool isPast(tz.TZDateTime dateTime) {
    return dateTime.isBefore(nowInIstanbul());
  }

  /// Verilen TZDateTime'ın gelecekte olup olmadığını kontrol eder
  /// [dateTime] - Kontrol edilecek TZDateTime
  /// Returns: Gelecekteyse true, değilse false
  /// Örnek:
  /// ```dart
  /// final futureTime = helper.tomorrowAt(9, 0);
  /// if (helper.isFuture(futureTime)) {
  ///   print('Bu saat henüz gelmedi');
  /// }
  /// ```
  bool isFuture(tz.TZDateTime dateTime) {
    return dateTime.isAfter(nowInIstanbul());
  }

  /// İki TZDateTime arasındaki farkı Duration olarak döndürür
  /// [start] - Başlangıç zamanı
  /// [end] - Bitiş zamanı
  /// Returns: İki zaman arasındaki fark
  /// Örnek:
  /// ```dart
  /// final now = helper.nowInIstanbul();
  /// final tomorrow = helper.tomorrowAt(9, 0);
  /// final difference = helper.difference(now, tomorrow);
  /// print('${difference.inHours} saat sonra');
  /// ```
  Duration difference(tz.TZDateTime start, tz.TZDateTime end) {
    return end.difference(start);
  }

  /// Verilen DateTime'ın bugün olup olmadığını kontrol eder
  /// [dateTime] - Kontrol edilecek DateTime
  /// Returns: Bugünse true, değilse false
  /// Örnek:
  /// ```dart
  /// final someDate = DateTime(2026, 1, 15);
  /// if (helper.isToday(someDate)) {
  ///   print('Bu tarih bugün');
  /// }
  /// ```
  bool isToday(DateTime dateTime) {
    final now = nowInIstanbul();
    final tzDateTime = toTZDateTime(dateTime);
    return tzDateTime.year == now.year &&
        tzDateTime.month == now.month &&
        tzDateTime.day == now.day;
  }

  /// Günün başlangıcını (00:00:00) döndürür
  /// [dateTime] - Referans tarih (opsiyonel, varsayılan bugün)
  /// Returns: Günün başlangıcı (00:00:00)
  /// Örnek:
  /// ```dart
  /// final startOfDay = helper.startOfDay();
  /// // Bugün saat 00:00:00
  /// ```
  tz.TZDateTime startOfDay([DateTime? dateTime]) {
    final reference = dateTime != null
        ? toTZDateTime(dateTime)
        : nowInIstanbul();
    return tz.TZDateTime(
      currentLocation,
      reference.year,
      reference.month,
      reference.day,
    );
  }

  /// Günün sonunu (23:59:59) döndürür
  /// [dateTime] - Referans tarih (opsiyonel, varsayılan bugün)
  /// Returns: Günün sonu (23:59:59)
  /// Örnek:
  /// ```dart
  /// final endOfDay = helper.endOfDay();
  /// // Bugün saat 23:59:59
  /// ```
  tz.TZDateTime endOfDay([DateTime? dateTime]) {
    final reference = dateTime != null
        ? toTZDateTime(dateTime)
        : nowInIstanbul();
    return tz.TZDateTime(
      currentLocation,
      reference.year,
      reference.month,
      reference.day,
      23,
      59,
      59,
    );
  }

  /// TZDateTime'ı okunabilir string'e çevirir
  /// [dateTime] - Formatlanacak TZDateTime
  /// Returns: Formatlanmış string (örn: "2026-01-15 14:30:00 Europe/Istanbul")
  /// Örnek:
  /// ```dart
  /// final now = helper.nowInIstanbul();
  /// print(helper.format(now));
  /// // Çıktı: "2026-01-15 14:30:00 Europe/Istanbul"
  /// ```
  String format(tz.TZDateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')} '
        '${dateTime.location.name}';
  }
}
