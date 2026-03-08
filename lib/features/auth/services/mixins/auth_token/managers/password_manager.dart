import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../data/services/password_hasher.dart';
import '../helpers/activity_log_helper.dart';
import '../helpers/auth_error_handler.dart';

/// Şifre yönetim sınıfı
///
/// Kullanıcı şifre işlemlerini yönetir.
class PasswordManager {
  final ActivityLogHelper _activityLogHelper;
  final Future<int?> Function() getUserId;
  final Future<Map<String, dynamic>?> Function() loadCurrentUser;

  PasswordManager({
    required this.getUserId,
    required this.loadCurrentUser,
    ActivityLogHelper? activityLogHelper,
  }) : _activityLogHelper = activityLogHelper ?? ActivityLogHelper();

  /// Şifre değiştirme
  ///
  /// Mevcut şifreyi doğrular ve yeni şifreyi hash'leyerek günceller.
  Future<String?> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final userId = await getUserId();
    if (userId == null) return 'Oturum açmanız gerekiyor.';

    try {
      final storedHash = await _getStoredPasswordHash(userId);

      if (!await _verifyCurrentPassword(currentPassword, storedHash)) {
        return 'Mevcut şifre yanlış.';
      }

      await _updatePassword(userId, newPassword);
      await _logPasswordChange(userId);

      return null;
    } catch (e) {
      return AuthErrorHandler.passwordChangeError(e);
    }
  }

  /// Veritabanından şifre hash'ini getirir
  Future<String> _getStoredPasswordHash(int userId) async {
    final result = await Supabase.instance.client
        .from('users')
        .select('password_hash')
        .eq('id', userId)
        .single();

    return result['password_hash'] as String;
  }

  /// Mevcut şifreyi doğrular
  Future<bool> _verifyCurrentPassword(
    String currentPassword,
    String storedHash,
  ) async {
    final passwordHasher = PasswordHasher.instance;

    if (passwordHasher.isValidHash(storedHash)) {
      return await passwordHasher.verifyPassword(currentPassword, storedHash);
    } else {
      return currentPassword == storedHash;
    }
  }

  /// Yeni şifreyi günceller
  Future<void> _updatePassword(int userId, String newPassword) async {
    final passwordHasher = PasswordHasher.instance;
    final newHashedPassword = await passwordHasher.hashPassword(newPassword);

    await Supabase.instance.client
        .from('users')
        .update({'password_hash': newHashedPassword})
        .eq('id', userId);
  }

  /// Şifre değişikliğini loglar
  Future<void> _logPasswordChange(int userId) async {
    final currentUser = await loadCurrentUser();
    if (currentUser != null) {
      await _activityLogHelper.logPasswordChange(
        userId: userId,
        username: currentUser['username'] ?? '',
      );
    }
  }
}
