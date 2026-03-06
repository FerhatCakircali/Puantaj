import '../constants/app_constants.dart';

/// Form validasyon utility fonksiyonları
/// Single Responsibility: Sadece validasyon işlemlerinden sorumlu
class ValidationUtils {
  // Private constructor - utility class
  ValidationUtils._();

  /// Kullanıcı adı validasyonu
    /// [username] - Kontrol edilecek kullanıcı adı
  /// Returns: Hata mesajı veya null (geçerli ise)
  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'Kullanıcı adı gereklidir';
    }

    if (username.length < AppConstants.minUsernameLength) {
      return 'Kullanıcı adı en az ${AppConstants.minUsernameLength} karakter olmalıdır';
    }

    if (username.length > AppConstants.maxUsernameLength) {
      return 'Kullanıcı adı en fazla ${AppConstants.maxUsernameLength} karakter olmalıdır';
    }

    // Sadece harf, rakam, alt çizgi ve nokta içerebilir
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_.]+$');
    if (!usernameRegex.hasMatch(username)) {
      return 'Kullanıcı adı sadece harf, rakam, alt çizgi ve nokta içerebilir';
    }

    return null;
  }

  /// Şifre validasyonu
    /// [password] - Kontrol edilecek şifre
  /// Returns: Hata mesajı veya null (geçerli ise)
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Şifre gereklidir';
    }

    if (password.length < AppConstants.minPasswordLength) {
      return 'Şifre en az ${AppConstants.minPasswordLength} karakter olmalıdır';
    }

    if (password.length > AppConstants.maxPasswordLength) {
      return 'Şifre en fazla ${AppConstants.maxPasswordLength} karakter olmalıdır';
    }

    return null;
  }

  /// Güçlü şifre validasyonu
    /// [password] - Kontrol edilecek şifre
  /// Returns: Hata mesajı veya null (geçerli ise)
  static String? validateStrongPassword(String? password) {
    final basicValidation = validatePassword(password);
    if (basicValidation != null) return basicValidation;

    // En az bir büyük harf
    if (!password!.contains(RegExp(r'[A-Z]'))) {
      return 'Şifre en az bir büyük harf içermelidir';
    }

    // En az bir küçük harf
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Şifre en az bir küçük harf içermelidir';
    }

    // En az bir rakam
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Şifre en az bir rakam içermelidir';
    }

    // En az bir özel karakter
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Şifre en az bir özel karakter içermelidir';
    }

    return null;
  }

  /// Şifre eşleşme validasyonu
    /// [password] - İlk şifre
  /// [confirmPassword] - Onay şifresi
  /// Returns: Hata mesajı veya null (eşleşiyorsa)
  static String? validatePasswordMatch(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Şifre onayı gereklidir';
    }

    if (password != confirmPassword) {
      return 'Şifreler eşleşmiyor';
    }

    return null;
  }

  /// Telefon numarası validasyonu (opsiyonel)
    /// [phone] - Kontrol edilecek telefon numarası
  /// Returns: Hata mesajı veya null (geçerli ise)
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return null; // Telefon opsiyonel
    }

    // Sadece rakam, boşluk, tire, parantez ve + içerebilir
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    if (cleanPhone.length < 10) {
      return 'Telefon numarası en az 10 rakam olmalıdır';
    }

    // Sadece rakam içermeli
    final phoneRegex = RegExp(r'^[0-9]+$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Geçerli bir telefon numarası giriniz';
    }

    return null;
  }

  /// Zorunlu alan validasyonu
    /// [value] - Kontrol edilecek değer
  /// [fieldName] - Alan adı (hata mesajı için)
  /// Returns: Hata mesajı veya null (dolu ise)
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName gereklidir';
    }
    return null;
  }

  /// Minimum uzunluk validasyonu
    /// [value] - Kontrol edilecek değer
  /// [minLength] - Minimum uzunluk
  /// [fieldName] - Alan adı (hata mesajı için)
  /// Returns: Hata mesajı veya null (geçerli ise)
  static String? validateMinLength(
    String? value,
    int minLength,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return null; // Boş değer kontrolü başka bir validatörde yapılmalı
    }

    if (value.length < minLength) {
      return '$fieldName en az $minLength karakter olmalıdır';
    }

    return null;
  }

  /// Maksimum uzunluk validasyonu
    /// [value] - Kontrol edilecek değer
  /// [maxLength] - Maksimum uzunluk
  /// [fieldName] - Alan adı (hata mesajı için)
  /// Returns: Hata mesajı veya null (geçerli ise)
  static String? validateMaxLength(
    String? value,
    int maxLength,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return null; // Boş değer kontrolü başka bir validatörde yapılmalı
    }

    if (value.length > maxLength) {
      return '$fieldName en fazla $maxLength karakter olmalıdır';
    }

    return null;
  }

  /// Sayı validasyonu
    /// [value] - Kontrol edilecek değer
  /// [fieldName] - Alan adı (hata mesajı için)
  /// Returns: Hata mesajı veya null (geçerli ise)
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return null; // Boş değer kontrolü başka bir validatörde yapılmalı
    }

    if (double.tryParse(value) == null) {
      return '$fieldName geçerli bir sayı olmalıdır';
    }

    return null;
  }

  /// Pozitif sayı validasyonu
    /// [value] - Kontrol edilecek değer
  /// [fieldName] - Alan adı (hata mesajı için)
  /// Returns: Hata mesajı veya null (geçerli ise)
  static String? validatePositiveNumber(String? value, String fieldName) {
    final numberValidation = validateNumber(value, fieldName);
    if (numberValidation != null) return numberValidation;

    final number = double.parse(value!);
    if (number <= 0) {
      return '$fieldName pozitif bir sayı olmalıdır';
    }

    return null;
  }

  /// Tarih validasyonu
    /// [value] - Kontrol edilecek tarih string'i
  /// [fieldName] - Alan adı (hata mesajı için)
  /// Returns: Hata mesajı veya null (geçerli ise)
  static String? validateDate(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return null; // Boş değer kontrolü başka bir validatörde yapılmalı
    }

    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return '$fieldName geçerli bir tarih olmalıdır';
    }
  }

  /// Gelecek tarih validasyonu
    /// [date] - Kontrol edilecek tarih
  /// [fieldName] - Alan adı (hata mesajı için)
  /// Returns: Hata mesajı veya null (geçerli ise)
  static String? validateFutureDate(DateTime? date, String fieldName) {
    if (date == null) {
      return null; // Boş değer kontrolü başka bir validatörde yapılmalı
    }

    if (date.isBefore(DateTime.now())) {
      return '$fieldName gelecekte bir tarih olmalıdır';
    }

    return null;
  }

  /// Geçmiş tarih validasyonu
    /// [date] - Kontrol edilecek tarih
  /// [fieldName] - Alan adı (hata mesajı için)
  /// Returns: Hata mesajı veya null (geçerli ise)
  static String? validatePastDate(DateTime? date, String fieldName) {
    if (date == null) {
      return null; // Boş değer kontrolü başka bir validatörde yapılmalı
    }

    if (date.isAfter(DateTime.now())) {
      return '$fieldName geçmişte bir tarih olmalıdır';
    }

    return null;
  }

  /// URL validasyonu
    /// [url] - Kontrol edilecek URL
  /// Returns: Hata mesajı veya null (geçerli ise)
  static String? validateUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null; // Boş değer kontrolü başka bir validatörde yapılmalı
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(url)) {
      return 'Geçerli bir URL giriniz';
    }

    return null;
  }

  /// Birden fazla validatör birleştirme
    /// [value] - Kontrol edilecek değer
  /// [validators] - Validatör fonksiyonları listesi
  /// Returns: İlk hata mesajı veya null (tümü geçerli ise)
  static String? combineValidators(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }
}
