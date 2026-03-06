import 'package:bcrypt/bcrypt.dart';

import '../../core/errors/app_exception.dart';

/// Şifre hash ve doğrulama servisi
/// bcrypt algoritması kullanarak güvenli şifre hash'leme ve doğrulama sağlar.
/// Singleton pattern ile tek instance garantisi.
/// Kullanım:
/// ```dart
/// final hasher = PasswordHasher.instance;
/// final hash = await hasher.hashPassword('myPassword123');
/// final isValid = await hasher.verifyPassword('myPassword123', hash);
/// ```
class PasswordHasher {
  PasswordHasher._();

  static final PasswordHasher _instance = PasswordHasher._();

  /// Singleton instance
  static PasswordHasher get instance => _instance;

  // bcrypt cost factor (10-12 önerilen, 10 daha hızlı)
  static const int _costFactor = 10;

  /// Şifreyi hash'ler
    /// bcrypt algoritması ile güvenli hash oluşturur.
  /// Salt otomatik olarak eklenir.
    /// [password] - Hash'lenecek şifre (minimum 6 karakter)
    /// Returns: Hash'lenmiş şifre string'i
    /// Throws:
  /// - [ValidationException] şifre çok kısa ise
  /// - [SecurityException] hash işlemi başarısız ise
  Future<String> hashPassword(String password) async {
    try {
      if (password.length < 6) {
        throw ValidationException('Şifre en az 6 karakter olmalıdır', {});
      }

      // bcrypt hash oluştur (async işlem)
      final hash = await Future.microtask(
        () => BCrypt.hashpw(password, BCrypt.gensalt(logRounds: _costFactor)),
      );

      return hash;
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw SecurityException('Şifre hash işlemi başarısız: $e');
    }
  }

  /// Şifreyi hash ile doğrular
    /// Verilen şifrenin hash ile eşleşip eşleşmediğini kontrol eder.
    /// [password] - Kontrol edilecek şifre
  /// [hash] - Veritabanından gelen hash
    /// Returns: true eşleşirse, false eşleşmezse
    /// Throws:
  /// - [SecurityException] doğrulama işlemi başarısız ise
  Future<bool> verifyPassword(String password, String hash) async {
    try {
      // Hash formatını kontrol et
      if (!isValidHash(hash)) {
        return false;
      }

      // bcrypt doğrulama (async işlem)
      final isPasswordValid = await Future.microtask(
        () => BCrypt.checkpw(password, hash),
      );

      return isPasswordValid;
    } catch (e) {
      // Hash format hatalarını false olarak döndür
      if (e.toString().contains('Invalid salt') ||
          e.toString().contains('Invalid argument')) {
        return false;
      }
      throw SecurityException('Şifre doğrulama işlemi başarısız: $e');
    }
  }

  /// Hash'in geçerli bir bcrypt hash'i olup olmadığını kontrol eder
    /// [hash] - Kontrol edilecek hash string'i
    /// Returns: true geçerli bcrypt hash ise, false değilse
  bool isValidHash(String hash) {
    try {
      // bcrypt hash formatı: $2a$10$... veya $2b$10$...
      // Toplam uzunluk 60 karakter olmalı
      final bcryptPattern = RegExp(r'^\$2[aby]\$\d{2}\$.{53}$');
      return bcryptPattern.hasMatch(hash);
    } catch (e) {
      return false;
    }
  }
}
