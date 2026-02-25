import 'package:intl/intl.dart';

/// Tarih işlemleri için utility fonksiyonları
///
/// Single Responsibility: Sadece tarih işlemlerinden sorumlu
class AppDateUtils {
  // Private constructor - utility class
  AppDateUtils._();

  // Date formatters
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'tr_TR');
  static final DateFormat _dayMonthFormat = DateFormat('dd MMMM', 'tr_TR');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

  /// Tarihi string'e çevirir (dd.MM.yyyy)
  ///
  /// [date] - Çevrilecek tarih
  /// Returns: Formatlanmış tarih string'i
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Tarih ve saati string'e çevirir (dd.MM.yyyy HH:mm)
  ///
  /// [dateTime] - Çevrilecek tarih ve saat
  /// Returns: Formatlanmış tarih-saat string'i
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  /// Saati string'e çevirir (HH:mm)
  ///
  /// [time] - Çevrilecek saat
  /// Returns: Formatlanmış saat string'i
  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  /// Ay ve yılı string'e çevirir (Ocak 2024)
  ///
  /// [date] - Çevrilecek tarih
  /// Returns: Formatlanmış ay-yıl string'i
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Gün ve ayı string'e çevirir (15 Ocak)
  ///
  /// [date] - Çevrilecek tarih
  /// Returns: Formatlanmış gün-ay string'i
  static String formatDayMonth(DateTime date) {
    return _dayMonthFormat.format(date);
  }

  /// ISO 8601 formatında string'e çevirir (yyyy-MM-dd)
  ///
  /// [date] - Çevrilecek tarih
  /// Returns: ISO formatında tarih string'i
  static String formatIso(DateTime date) {
    return _isoFormat.format(date);
  }

  /// String'i DateTime'a çevirir (dd.MM.yyyy)
  ///
  /// [dateString] - Parse edilecek string
  /// Returns: DateTime nesnesi veya null
  static DateTime? parseDate(String dateString) {
    try {
      return _dateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// String'i DateTime'a çevirir (dd.MM.yyyy HH:mm)
  ///
  /// [dateTimeString] - Parse edilecek string
  /// Returns: DateTime nesnesi veya null
  static DateTime? parseDateTime(String dateTimeString) {
    try {
      return _dateTimeFormat.parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }

  /// ISO 8601 string'ini DateTime'a çevirir
  ///
  /// [isoString] - Parse edilecek ISO string
  /// Returns: DateTime nesnesi veya null
  static DateTime? parseIso(String isoString) {
    try {
      return DateTime.parse(isoString);
    } catch (e) {
      return null;
    }
  }

  /// Bugünün tarihini döndürür (saat bilgisi olmadan)
  ///
  /// Returns: Bugünün tarihi
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Yarının tarihini döndürür
  ///
  /// Returns: Yarının tarihi
  static DateTime tomorrow() {
    return today().add(const Duration(days: 1));
  }

  /// Dünün tarihini döndürür
  ///
  /// Returns: Dünün tarihi
  static DateTime yesterday() {
    return today().subtract(const Duration(days: 1));
  }

  /// Ayın ilk gününü döndürür
  ///
  /// [date] - Referans tarih (opsiyonel, varsayılan: bugün)
  /// Returns: Ayın ilk günü
  static DateTime firstDayOfMonth([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month, 1);
  }

  /// Ayın son gününü döndürür
  ///
  /// [date] - Referans tarih (opsiyonel, varsayılan: bugün)
  /// Returns: Ayın son günü
  static DateTime lastDayOfMonth([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month + 1, 0);
  }

  /// İki tarih arasındaki gün farkını hesaplar
  ///
  /// [date1] - İlk tarih
  /// [date2] - İkinci tarih
  /// Returns: Gün farkı
  static int daysBetween(DateTime date1, DateTime date2) {
    final d1 = DateTime(date1.year, date1.month, date1.day);
    final d2 = DateTime(date2.year, date2.month, date2.day);
    return d2.difference(d1).inDays;
  }

  /// Tarihin bugün olup olmadığını kontrol eder
  ///
  /// [date] - Kontrol edilecek tarih
  /// Returns: true ise bugün, false değilse
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Tarihin yarın olup olmadığını kontrol eder
  ///
  /// [date] - Kontrol edilecek tarih
  /// Returns: true ise yarın, false değilse
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Tarihin dün olup olmadığını kontrol eder
  ///
  /// [date] - Kontrol edilecek tarih
  /// Returns: true ise dün, false değilse
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Tarihin geçmişte olup olmadığını kontrol eder
  ///
  /// [date] - Kontrol edilecek tarih
  /// Returns: true ise geçmişte, false değilse
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  /// Tarihin gelecekte olup olmadığını kontrol eder
  ///
  /// [date] - Kontrol edilecek tarih
  /// Returns: true ise gelecekte, false değilse
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  /// Tarihin aynı ay olup olmadığını kontrol eder
  ///
  /// [date1] - İlk tarih
  /// [date2] - İkinci tarih
  /// Returns: true ise aynı ay, false değilse
  static bool isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  /// Tarihin aynı gün olup olmadığını kontrol eder
  ///
  /// [date1] - İlk tarih
  /// [date2] - İkinci tarih
  /// Returns: true ise aynı gün, false değilse
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Relative time string döndürür (örn: "2 saat önce")
  ///
  /// [dateTime] - Referans tarih
  /// Returns: Relative time string
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years yıl önce';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ay önce';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  /// Tarih aralığı oluşturur
  ///
  /// [start] - Başlangıç tarihi
  /// [end] - Bitiş tarihi
  /// Returns: Tarih listesi
  static List<DateTime> getDateRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    var current = start;

    while (current.isBefore(end) || isSameDay(current, end)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  /// Haftanın günü adını döndürür
  ///
  /// [date] - Tarih
  /// Returns: Gün adı (Pazartesi, Salı, vb.)
  static String getWeekdayName(DateTime date) {
    const weekdays = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    return weekdays[date.weekday - 1];
  }

  /// Ayın adını döndürür
  ///
  /// [month] - Ay numarası (1-12)
  /// Returns: Ay adı (Ocak, Şubat, vb.)
  static String getMonthName(int month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return months[month - 1];
  }
}
