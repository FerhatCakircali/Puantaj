import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/services/password_hasher.dart';
import '../senders/email_sender.dart';
import '../templates/password_reset_template.dart';
import '../utils/token_generator.dart';
import '../../../core/constants/database_constants.dart';

/// Şifre sıfırlama işlemlerini yöneten sınıf
class PasswordResetHandler {
  final _supabase = Supabase.instance.client;
  final EmailSender _emailSender = EmailSender();

  /// Şifre sıfırlama email'i gönderir
  Future<String?> sendPasswordResetEmail({
    required String email,
    required String userType,
  }) async {
    try {
      debugPrint('Şifre sıfırlama email\'i gönderiliyor: $email');
      debugPrint('User Type: $userType');

      final userData = await _findUserByEmail(email, userType);
      if (userData == null) {
        debugPrint('Email bulunamadı: $email (userType: $userType)');
        return 'Bu e-posta adresi sistemde kayıtlı değil.';
      }

      debugPrint('Kullanıcı bulundu: ${userData['username']}');

      final userId = userData['id'] as int;
      final username = userData['username'] as String;
      final token = TokenGenerator.generateResetToken();

      debugPrint('Token oluşturuluyor...');
      await _supabase.rpc(
        'create_password_reset_token',
        params: {
          'p_user_type': userType,
          'p_user_id': userId,
          'p_email': email,
          'p_token': token,
        },
      );

      debugPrint('Token oluşturuldu: $token');

      final emailSent = await _emailSender.sendEmail(
        to: email,
        subject: 'Şifre Sıfırlama Kodu - Puantaj Sistemi',
        html: PasswordResetTemplate.build(username, token),
      );

      if (!emailSent) {
        return 'Email gönderilemedi. Lütfen tekrar deneyin.';
      }

      return null;
    } catch (e) {
      debugPrint('Email gönderme hatası: $e');
      return 'Email gönderilirken bir hata oluştu: $e';
    }
  }

  /// Email ile kullanıcı bulur
  Future<Map<String, dynamic>?> _findUserByEmail(
    String email,
    String userType,
  ) async {
    try {
      final table = userType == 'user'
          ? DatabaseConstants.usersTable
          : DatabaseConstants.workersTable;
      debugPrint('Email araniyor: $email (tablo: $table)');

      final result = await _supabase
          .from(table)
          .select('id, username, email')
          .eq('email', email.toLowerCase())
          .maybeSingle();

      if (result == null) {
        debugPrint('Email bulunamadi: $email');
      } else {
        debugPrint(
          'Email bulundu: ${result['username']} (id: ${result['id']})',
        );
      }

      return result;
    } catch (e) {
      debugPrint('Email ile kullanıcı bulma hatası: $e');
      return null;
    }
  }

  /// Şifre sıfırlama token'ını doğrular
  Future<String?> verifyResetToken(String token) async {
    try {
      final result =
          await _supabase.rpc('verify_reset_token', params: {'p_token': token})
              as List<dynamic>;

      if (result.isEmpty) {
        return 'Geçersiz veya süresi dolmuş kod.';
      }

      final data = result.first as Map<String, dynamic>;
      final isValid = data['is_valid'] as bool;

      if (!isValid) {
        return 'Geçersiz veya süresi dolmuş kod.';
      }

      return null;
    } catch (e) {
      debugPrint('Token doğrulama hatası: $e');
      return 'Token doğrulanırken bir hata oluştu.';
    }
  }

  /// Token ile şifre sıfırlar
  Future<String?> resetPasswordWithToken({
    required String token,
    required String newPassword,
  }) async {
    try {
      debugPrint('Şifre sıfırlanıyor...');

      final passwordHasher = PasswordHasher.instance;
      final hashedPassword = await passwordHasher.hashPassword(newPassword);

      final result =
          await _supabase.rpc(
                'reset_password_with_token',
                params: {
                  'p_token': token,
                  'p_new_password_hash': hashedPassword,
                },
              )
              as bool;

      if (!result) {
        return 'Geçersiz veya süresi dolmuş kod.';
      }

      debugPrint('Şifre başarıyla sıfırlandı');
      return null;
    } catch (e) {
      debugPrint('Şifre sıfırlama hatası: $e');
      return 'Şifre sıfırlanırken bir hata oluştu.';
    }
  }

  /// Şifre sıfırlama token bilgilerini alır
  Future<Map<String, dynamic>?> getResetTokenData(String token) async {
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
}
