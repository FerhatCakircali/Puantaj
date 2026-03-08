import 'dart:math';

/// Token oluşturma yardımcı sınıfı
class TokenGenerator {
  /// 6 haneli rastgele kod oluşturur
  static String generateResetToken() {
    final random = Random.secure();
    final code = random.nextInt(900000) + 100000;
    return code.toString();
  }
}
