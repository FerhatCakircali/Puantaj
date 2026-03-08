import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/token_generator.dart';
import '../../../core/constants/database_constants.dart';

/// Email doğrulama işlemlerini yöneten sınıf
class EmailVerificationHandler {
  final _supabase = Supabase.instance.client;

  /// Email doğrulama kodu gönderir
  Future<String?> sendVerificationEmail({
    required String email,
    required String userType,
    required int userId,
  }) async {
    try {
      debugPrint('Email doğrulama kodu gönderiliyor: $email');

      final token = TokenGenerator.generateResetToken();

      await _supabase.rpc(
        'create_password_reset_token',
        params: {
          'p_user_type': userType,
          'p_user_id': userId,
          'p_email': email,
          'p_token': token,
        },
      );

      debugPrint('Email doğrulama kodu oluşturuldu: $token');

      return null;
    } catch (e) {
      debugPrint('Email doğrulama kodu gönderme hatası: $e');
      return 'Doğrulama kodu gönderilirken bir hata oluştu.';
    }
  }

  /// Email doğrulama kodunu kontrol eder
  Future<String?> verifyEmail({
    required String token,
    required String userType,
    required int userId,
  }) async {
    try {
      final tokenData = await _getResetTokenData(token);
      if (tokenData == null) {
        return 'Geçersiz veya süresi dolmuş kod.';
      }

      final table = userType == 'user'
          ? DatabaseConstants.usersTable
          : DatabaseConstants.workersTable;
      await _supabase
          .from(table)
          .update({'email_verified': true})
          .eq('id', userId);

      await _supabase
          .from('password_reset_tokens')
          .update({'used': true})
          .eq('token', token);

      debugPrint('Email doğrulandı');
      return null;
    } catch (e) {
      debugPrint('Email doğrulama hatası: $e');
      return 'Email doğrulanırken bir hata oluştu.';
    }
  }

  /// Token bilgilerini alır
  Future<Map<String, dynamic>?> _getResetTokenData(String token) async {
    try {
      final result =
          await _supabase.rpc('verify_reset_token', params: {'p_token': token})
              as List<dynamic>;

      if (result.isEmpty) {
        return null;
      }

      final data = result.first as Map<String, dynamic>;
      final isValid = data['is_valid'] as bool;

      if (!isValid) {
        return null;
      }

      return data;
    } catch (e) {
      debugPrint('Token doğrulama hatası: $e');
      return null;
    }
  }

  /// Süresi dolmuş token'ları temizler
  Future<void> cleanupExpiredTokens() async {
    try {
      final result = await _supabase.rpc('cleanup_expired_reset_tokens');
      debugPrint('$result adet süresi dolmuş token temizlendi');
    } catch (e) {
      debugPrint('Token temizleme hatası: $e');
    }
  }
}
