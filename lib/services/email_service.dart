import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/services/password_hasher.dart';

/// Email gönderme servisi - Resend API kullanır
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  final _supabase = Supabase.instance.client;

  static const String _resendApiUrl = 'https://api.resend.com/emails';
  String get _apiKey => dotenv.env['RESEND_API_KEY'] ?? '';
  static const String _fromEmail = 'onboarding@resend.dev';
  static const String _fromName = 'Puantaj Sistemi';

  /// Resend API ile email gönder
  Future<bool> _sendEmail({
    required String to,
    required String subject,
    required String html,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_resendApiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': '$_fromName <$_fromEmail>',
          'to': [to],
          'subject': subject,
          'html': html,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Email başarıyla gönderildi: $to');
        return true;
      } else {
        debugPrint('❌ Email gönderme hatası: ${response.statusCode}');
        debugPrint('   Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Email gönderme exception: $e');
      return false;
    }
  }

  /// Şifre sıfırlama email HTML şablonu
  String _buildPasswordResetEmailHtml(String username, String code) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
    }
    .container {
      background: #ffffff;
      border-radius: 10px;
      padding: 40px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }
    .header {
      text-align: center;
      margin-bottom: 30px;
    }
    .header h1 {
      color: #4F46E5;
      margin: 0;
      font-size: 28px;
    }
    .code-box {
      background: #F3F4F6;
      border: 2px dashed #4F46E5;
      border-radius: 8px;
      padding: 20px;
      text-align: center;
      margin: 30px 0;
    }
    .code {
      font-size: 36px;
      font-weight: bold;
      color: #4F46E5;
      letter-spacing: 8px;
      font-family: 'Courier New', monospace;
    }
    .info {
      background: #FEF3C7;
      border-left: 4px solid #F59E0B;
      padding: 15px;
      margin: 20px 0;
      border-radius: 4px;
    }
    .footer {
      text-align: center;
      margin-top: 30px;
      padding-top: 20px;
      border-top: 1px solid #E5E7EB;
      color: #6B7280;
      font-size: 14px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🔐 Şifre Sıfırlama</h1>
    </div>
    
    <p>Merhaba <strong>$username</strong>,</p>
    
    <p>Şifre sıfırlama talebiniz alındı. Aşağıdaki 6 haneli kodu kullanarak yeni şifrenizi belirleyebilirsiniz:</p>
    
    <div class="code-box">
      <div class="code">$code</div>
    </div>
    
    <div class="info">
      <strong>⏰ Önemli:</strong> Bu kod 24 saat geçerlidir ve tek kullanımlıktır.
    </div>
    
    <p>Eğer bu talebi siz yapmadıysanız, bu email'i görmezden gelebilirsiniz. Şifreniz değiştirilmeyecektir.</p>
    
    <div class="footer">
      <p>Bu email otomatik olarak gönderilmiştir.</p>
      <p><strong>Puantaj Yönetim Sistemi</strong></p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Şifre sıfırlama email'i gönder
  Future<String?> sendPasswordResetEmail({
    required String email,
    required String userType,
  }) async {
    try {
      debugPrint('📧 Şifre sıfırlama email\'i gönderiliyor: $email');

      final userData = await _findUserByEmail(email, userType);
      if (userData == null) {
        return 'Bu email adresi sistemde kayıtlı değil.';
      }

      final userId = userData['id'] as int;
      final username = userData['username'] as String;
      final token = _generateResetToken();

      await _supabase.rpc(
        'create_password_reset_token',
        params: {
          'p_user_type': userType,
          'p_user_id': userId,
          'p_email': email,
          'p_token': token,
        },
      );

      debugPrint('✅ Token oluşturuldu: $token');

      final emailSent = await _sendEmail(
        to: email,
        subject: 'Şifre Sıfırlama Kodu - Puantaj Sistemi',
        html: _buildPasswordResetEmailHtml(username, token),
      );

      if (!emailSent) {
        return 'Email gönderilemedi. Lütfen tekrar deneyin.';
      }

      return null;
    } catch (e) {
      debugPrint('❌ Email gönderme hatası: $e');
      return 'Email gönderilirken bir hata oluştu.';
    }
  }

  /// Email ile kullanıcı bul
  Future<Map<String, dynamic>?> _findUserByEmail(
    String email,
    String userType,
  ) async {
    try {
      final table = userType == 'user' ? 'users' : 'workers';
      final result = await _supabase
          .from(table)
          .select('id, username, email')
          .eq('email', email.toLowerCase())
          .maybeSingle();

      return result;
    } catch (e) {
      debugPrint('Email ile kullanıcı bulma hatası: $e');
      return null;
    }
  }

  /// Şifre sıfırlama token'ını doğrula (sadece doğrulama için)
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

      return null; // Başarılı
    } catch (e) {
      debugPrint('Token doğrulama hatası: $e');
      return 'Token doğrulanırken bir hata oluştu.';
    }
  }

  /// Şifre sıfırlama token'ı bilgilerini al
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

  /// Token ile şifre sıfırla
  Future<String?> resetPasswordWithToken({
    required String token,
    required String newPassword,
  }) async {
    try {
      debugPrint('🔐 Şifre sıfırlanıyor...');

      // Yeni şifreyi hash'le
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

      debugPrint('✅ Şifre başarıyla sıfırlandı');
      return null;
    } catch (e) {
      debugPrint('❌ Şifre sıfırlama hatası: $e');
      return 'Şifre sıfırlanırken bir hata oluştu.';
    }
  }

  /// 6 haneli rastgele kod oluştur
  String _generateResetToken() {
    final random = Random.secure();
    final code = random.nextInt(900000) + 100000;
    return code.toString();
  }

  /// Email doğrulama kodu gönder
  Future<String?> sendVerificationEmail({
    required String email,
    required String userType,
    required int userId,
  }) async {
    try {
      debugPrint('📧 Email doğrulama kodu gönderiliyor: $email');

      final token = _generateResetToken();

      await _supabase.rpc(
        'create_password_reset_token',
        params: {
          'p_user_type': userType,
          'p_user_id': userId,
          'p_email': email,
          'p_token': token,
        },
      );

      debugPrint('✅ Email doğrulama kodu oluşturuldu: $token');

      return null;
    } catch (e) {
      debugPrint('❌ Email doğrulama kodu gönderme hatası: $e');
      return 'Doğrulama kodu gönderilirken bir hata oluştu.';
    }
  }

  /// Email doğrulama kodunu kontrol et
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

      final table = userType == 'user' ? 'users' : 'workers';
      await _supabase
          .from(table)
          .update({'email_verified': true})
          .eq('id', userId);

      await _supabase
          .from('password_reset_tokens')
          .update({'used': true})
          .eq('token', token);

      debugPrint('✅ Email doğrulandı');
      return null;
    } catch (e) {
      debugPrint('❌ Email doğrulama hatası: $e');
      return 'Email doğrulanırken bir hata oluştu.';
    }
  }

  /// Süresi dolmuş token'ları temizle
  Future<void> cleanupExpiredTokens() async {
    try {
      final result = await _supabase.rpc('cleanup_expired_reset_tokens');
      debugPrint('🧹 $result adet süresi dolmuş token temizlendi');
    } catch (e) {
      debugPrint('Token temizleme hatası: $e');
    }
  }
}
