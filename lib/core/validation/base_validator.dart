import '../error_logger.dart';

/// Tüm validator'lar için base sınıf
///
/// Ortak validation metodlarını ve error handling pattern'ini sağlar
abstract class BaseValidator {
  /// ID validasyonu yapar
  ///
  /// [id] Kontrol edilecek ID
  /// [fieldName] Hata mesajında kullanılacak alan adı
  /// Throws: [ArgumentError] ID geçersizse
  void validateId(int id, {String fieldName = 'ID'}) {
    if (id <= 0) {
      throw ArgumentError('Geçersiz $fieldName');
    }
  }

  /// Pozitif sayı validasyonu yapar
  ///
  /// [value] Kontrol edilecek değer
  /// [fieldName] Hata mesajında kullanılacak alan adı
  /// Throws: [ArgumentError] Değer negatifse
  void validatePositive(num value, {String fieldName = 'Değer'}) {
    if (value < 0) {
      throw ArgumentError('$fieldName negatif olamaz');
    }
  }

  /// Null veya boş string kontrolü yapar
  ///
  /// [value] Kontrol edilecek değer
  /// [fieldName] Hata mesajında kullanılacak alan adı
  /// Returns: Hata mesajı veya null
  String? validateRequired(String? value, {String fieldName = 'Alan'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName boş olamaz';
    }
    return null;
  }

  /// Tutar validasyonu yapar (string input)
  ///
  /// [value] Kontrol edilecek tutar string'i
  /// [fieldName] Hata mesajında kullanılacak alan adı
  /// Returns: Hata mesajı veya null
  String? validateAmount(String? value, {String fieldName = 'Tutar'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName girin';
    }

    final cleanValue = value.replaceAll('.', '');
    final amount = double.tryParse(cleanValue);

    if (amount == null || amount <= 0) {
      return 'Geçerli bir $fieldName girin';
    }

    return null;
  }

  /// Tutar string'ini double'a çevirir
  ///
  /// [value] Çevrilecek string
  /// Returns: Parse edilmiş double değer
  double parseAmount(String value) {
    final cleanValue = value.replaceAll('.', '');
    return double.parse(cleanValue);
  }

  /// Tarih aralığı validasyonu yapar
  ///
  /// [startDate] Başlangıç tarihi
  /// [endDate] Bitiş tarihi
  /// Throws: [ArgumentError] Bitiş tarihi başlangıçtan önceyse
  void validateDateRange(DateTime startDate, DateTime endDate) {
    if (endDate.isBefore(startDate)) {
      throw ArgumentError('Bitiş tarihi başlangıç tarihinden önce olamaz');
    }
  }

  /// Async validation işlemlerini error handling ile wrap eder
  ///
  /// [operation] Çalıştırılacak async işlem
  /// [context] Error log için context bilgisi
  /// [fallbackValue] Hata durumunda dönülecek değer
  /// Returns: İşlem sonucu veya fallback değer
  Future<T> executeValidation<T>(
    Future<T> Function() operation,
    T fallbackValue, {
    required String context,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(context, error: e, stackTrace: stackTrace);
      return fallbackValue;
    }
  }
}
