/// Şifre validasyon işlemlerini yöneten helper sınıfı
class PasswordValidator {
  /// Minimum şifre uzunluğu
  static const int minPasswordLength = 6;

  /// Tüm alanların dolu olup olmadığını kontrol eder
  static bool areAllFieldsFilled({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    return currentPassword.trim().isNotEmpty &&
        newPassword.trim().isNotEmpty &&
        confirmPassword.trim().isNotEmpty;
  }

  /// Yeni şifrenin minimum uzunluk gereksinimini karşılayıp karşılamadığını kontrol eder
  static bool isNewPasswordValid(String newPassword) {
    return newPassword.trim().length >= minPasswordLength;
  }

  /// Yeni şifre ile onay şifresinin eşleşip eşleşmediğini kontrol eder
  static bool doPasswordsMatch({
    required String newPassword,
    required String confirmPassword,
  }) {
    return newPassword.trim() == confirmPassword.trim();
  }

  /// Validasyon hatası mesajlarını döndürür
  static String? getValidationError({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    if (!areAllFieldsFilled(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    )) {
      return 'Lütfen tüm şifre alanlarını doldurunuz.';
    }

    if (!isNewPasswordValid(newPassword)) {
      return 'Yeni şifre en az $minPasswordLength karakter olmalıdır.';
    }

    if (!doPasswordsMatch(
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    )) {
      return 'Yeni şifreler eşleşmiyor.';
    }

    return null;
  }
}
