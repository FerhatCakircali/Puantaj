import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  /// Yerel tarihi UTC olarak dönüştürür
  DateTime toUtc() {
    return DateTime.utc(
      year,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
  }

  /// UTC tarihini yerel tarih olarak dönüştürür
  DateTime toLocal() {
    return isUtc
        ? DateTime(
          year,
          month,
          day,
          hour,
          minute,
          second,
          millisecond,
          microsecond,
        )
        : this;
  }

  /// Sadece tarih bileşenlerini UTC olarak döndürür (saat 00:00:00)
  DateTime toUtcDate() {
    return DateTime.utc(year, month, day);
  }

  /// Sadece tarih bileşenlerini yerel olarak döndürür (saat 00:00:00)
  DateTime toLocalDate() {
    return DateTime(year, month, day);
  }

  /// Tarih formatını standartlaştırır
  String toStandardFormat() {
    return '${year.toString()}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
  }

  /// Tarih formatını kullanıcı dostu şekilde formatlar
  String toFriendlyFormat() {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  /// Gelecek tarih mi kontrolü
  bool get isFutureDate {
    final today = DateTime.now().toLocalDate();
    return toLocalDate().isAfter(today);
  }

  /// Geçmiş tarih mi kontrolü
  bool get isPastDate {
    final today = DateTime.now().toLocalDate();
    return toLocalDate().isBefore(today);
  }
}
