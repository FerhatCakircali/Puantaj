import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/services/password_hasher.dart';

/// Email gönderme servisi - Supabase Functions kullanır
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  final _supabase = Supabase.instance.client;

  /// Supabase Edge Function ile email gönder
  Future<bool> _sendEmail({
    required String to,
    required String subject,
    required String html,
  }) async {
    try {
      // Supabase Edge Function'ı çağır
      final response = await _supabase.functions.invoke(
        'send-email',
        body: {'to': to, 'subject': subject, 'html': html},
      );

      if (response.status == 200) {
        debugPrint('✅ Email başarıyla gönderildi: $to');
        return true;
      } else {
        debugPrint('❌ Email gönderme hatası: ${response.status}');
        debugPrint('   Response: ${response.data}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Email gönderme exception: $e');
      return false;
    }
  }

  String _buildPasswordResetEmailHtml(String username, String code) {
    return '''
<!DOCTYPE html>
<html lang="tr" xmlns:v="urn:schemas-microsoft-com:vml">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Puantaj | Şifre Sıfırlama</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@600;800&display=swap');
    :root { color-scheme: light dark; }
    body { margin: 0; padding: 0; width: 100% !important; background-color: #F4F4F5; font-family: 'Inter', sans-serif; -webkit-font-smoothing: antialiased; }
    .wrapper { width: 100%; background-color: #F4F4F5; padding: 60px 0; }
    .ticket-card { max-width: 500px; margin: 0 auto; background: #FFFFFF; border: 1px solid #E4E4E7; border-radius: 24px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.03); }
    .card-body { padding: 48px 40px; }
    
    /* İkonu Şıklaştıran Yeni Stil */
    .logo-container {
      width: 64px; height: 64px;
      border-radius: 16px;
      overflow: hidden;
      border: 1px solid #E4E4E7;
      box-shadow: 0 4px 10px rgba(0,0,0,0.05);
    }
    .brand-logo { width: 64px; height: 64px; display: block; border: 0; }

    .brand-title { font-size: 22px; font-weight: 700; color: #18181B; margin: 0; line-height: 1.2; }
    .brand-subtitle { font-size: 14px; color: #71717A; margin: 0; }
    .h1 { font-size: 28px; font-weight: 700; color: #09090B; letter-spacing: -0.5px; margin: 32px 0 16px 0; }
    .p { font-size: 15px; color: #52525B; line-height: 1.6; margin-bottom: 32px; }
    
    .code-box { background: #F8FAFC; border: 1px solid #E2E8F0; border-left: 4px solid #4F46E5; border-radius: 16px; padding: 32px; margin-bottom: 32px; text-align: center; }
    .code-number { font-family: 'JetBrains Mono', monospace; font-size: 42px; font-weight: 800; color: #4F46E5; letter-spacing: 10px; margin: 0; }

    @media (prefers-color-scheme: dark) {
      body, .wrapper { background-color: #000000 !important; }
      .ticket-card { background: #09090B !important; border-color: #27272A !important; }
      .brand-title, .h1 { color: #FAFAFA !important; }
      .p { color: #A1A1AA !important; }
      .code-box { background: #18181B !important; border-color: #27272A !important; }
      .code-number { color: #818CF8 !important; }
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <table width="100%" border="0" cellspacing="0" cellpadding="0" role="presentation">
      <tr>
        <td align="center">
          <div class="ticket-card">
            <div class="card-body">
              <table border="0" cellspacing="0" cellpadding="0" role="presentation">
                <tr>
                  <td style="vertical-align: middle;">
                    <div class="logo-container">
                      <img src="https://uvdcefauzxordqgvvweq.supabase.co/storage/v1/object/public/app-assets/icon.png" class="brand-logo" alt="Puantaj">
                    </div>
                  </td>
                  <td style="padding-left: 16px; vertical-align: middle;">
                    <h2 class="brand-title">Puantaj</h2>
                    <p class="brand-subtitle">Yönetim Sistemi</p>
                  </td>
                </tr>
              </table>

              <h1 class="h1">Şifre Sıfırlama Talebi</h1>
              <p class="p">
                Merhaba <strong>$username</strong>,<br><br>
                Puantaj hesabınız için bir şifre sıfırlama talebi aldık. İşleminize devam etmek için aşağıdaki doğrulama kodunu kullanabilirsiniz:
              </p>

              <div class="code-box">
                <div style="font-size: 11px; font-weight: 700; color: #64748B; letter-spacing: 1.5px; text-transform: uppercase; margin-bottom: 12px;">Doğrulama Kodu</div>
                <h2 class="code-number">$code</h2>
              </div>

              <p style="font-size: 13px; color: #71717A; border-top: 1px solid #F4F4F5; padding-top: 24px;">
                Eğer bu talebi siz yapmadıysanız, bu e-postayı güvenle görmezden gelebilirsiniz. 
              </p>
            </div>
          </div>
          <p style="text-align: center; font-size: 12px; color: #A1A1AA; margin-top: 24px;">
            © 2026 Puantaj. Tüm hakları saklıdır.
          </p>
        </td>
      </tr>
    </table>
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
      debugPrint('   User Type: $userType');

      final userData = await _findUserByEmail(email, userType);
      if (userData == null) {
        debugPrint('❌ Email bulunamadı: $email (userType: $userType)');
        return 'Bu e-posta adresi sistemde kayıtlı değil.';
      }

      debugPrint('✅ Kullanıcı bulundu: ${userData['username']}');

      final userId = userData['id'] as int;
      final username = userData['username'] as String;
      final token = _generateResetToken();

      debugPrint('🔑 Token oluşturuluyor...');
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
      return 'Email gönderilirken bir hata oluştu: $e';
    }
  }

  /// Email ile kullanıcı bul
  Future<Map<String, dynamic>?> _findUserByEmail(
    String email,
    String userType,
  ) async {
    try {
      final table = userType == 'user' ? 'users' : 'workers';
      debugPrint('🔍 Email araniyor: $email (tablo: $table)');

      final result = await _supabase
          .from(table)
          .select('id, username, email')
          .eq('email', email.toLowerCase())
          .maybeSingle();

      if (result == null) {
        debugPrint('❌ Email bulunamadi: $email');
      } else {
        debugPrint(
          '✅ Email bulundu: ${result['username']} (id: ${result['id']})',
        );
      }

      return result;
    } catch (e) {
      debugPrint('❌ Email ile kullanıcı bulma hatası: $e');
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
