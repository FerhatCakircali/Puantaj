import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../data/services/password_hasher.dart';

/// Eski plain text şifreleri bcrypt'e migrate eden sınıf
class PasswordMigrationHandler {
  final PasswordHasher _passwordHasher = PasswordHasher.instance;

  /// Şifreyi doğrular ve gerekirse hash'e migrate eder
  ///
  /// Returns: Şifre doğru mu?
  Future<bool> validateAndMigratePassword({
    required String password,
    required String storedHash,
    required int userId,
  }) async {
    bool isPasswordValid;

    if (_passwordHasher.isValidHash(storedHash)) {
      isPasswordValid = await _passwordHasher.verifyPassword(
        password,
        storedHash,
      );
    } else {
      isPasswordValid = password == storedHash;

      if (isPasswordValid) {
        await _migrateToHashedPassword(password, userId);
      }
    }

    return isPasswordValid;
  }

  /// Plain text şifreyi hash'e dönüştürür ve veritabanını günceller
  Future<void> _migrateToHashedPassword(String password, int userId) async {
    try {
      final newHash = await _passwordHasher.hashPassword(password);
      await Supabase.instance.client
          .from('users')
          .update({'password_hash': newHash})
          .eq('id', userId);
      debugPrint('Kullanıcı şifresi hash\'lendi: $userId');
    } catch (e) {
      debugPrint('Şifre hash\'leme hatası: $e');
    }
  }
}
