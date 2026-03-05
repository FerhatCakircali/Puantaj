import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/services/password_hasher.dart';
import '../../../../services/validation_service.dart';

mixin AuthRegisterMixin {
  final _validationService = ValidationService.instance;

  /// Yeni kullanıcı kaydı
  Future<String?> register(
    String username,
    String password,
    String firstName,
    String lastName,
    String jobTitle, {
    bool isAdmin = false,
    String? email,
  }) async {
    try {
      final lowercaseUsername = username.toLowerCase();

      final usernameError = _validationService.validateUsernameFormat(
        lowercaseUsername,
      );
      if (usernameError != null) {
        return usernameError;
      }

      final usernameAvailability = await _validationService
          .checkUsernameAvailability(lowercaseUsername);
      if (usernameAvailability != null) {
        return usernameAvailability;
      }

      // E-posta kontrolü (zorunlu)
      if (email == null || email.isEmpty) {
        return 'E-posta adresi gerekli';
      }

      final emailFormatError = _validationService.validateEmailFormat(email);
      if (emailFormatError != null) {
        return emailFormatError;
      }

      final emailAvailability = await _validationService.checkEmailAvailability(
        email,
      );
      if (emailAvailability != null) {
        return emailAvailability;
      }

      // Şifreyi hash'le
      final passwordHasher = PasswordHasher.instance;
      final hashedPassword = await passwordHasher.hashPassword(password);

      final data = {
        'username': lowercaseUsername,
        'password_hash': hashedPassword,
        'first_name': firstName,
        'last_name': lastName,
        'job_title': jobTitle,
        'is_admin': isAdmin,
        'is_blocked': true,
        'email': email.toLowerCase(),
      };

      await Supabase.instance.client
          .from('users')
          .insert(data)
          .select('id')
          .single();

      return null;
    } catch (e) {
      debugPrint('Kayıt sırasında hata: $e');
      if (e is PostgrestException && e.code == '23505') {
        if (e.message.contains('email')) {
          return 'Bu e-posta adresi zaten kullanılıyor';
        }
      }
      return 'Bir hata oluştu';
    }
  }

  /// Kullanıcı adı validasyonu (wrapper for ValidationService)
  String? validateUsername(String username) {
    return _validationService.validateUsernameFormat(username);
  }

  /// Kullanıcı adı kullanılabilirlik kontrolü (wrapper for ValidationService)
  Future<String?> checkUsernameAvailability(String username) async {
    return await _validationService.checkUsernameAvailability(username);
  }

  /// Email kullanılabilirlik kontrolü (wrapper for ValidationService)
  Future<String?> checkEmailAvailability(String email) async {
    return await _validationService.checkEmailAvailability(email);
  }

  /// Admin kullanıcı oluştur (yoksa)
  Future<void> createAdminIfNotExists() async {
    try {
      debugPrint('Admin kullanıcı kontrolü başlatılıyor...');

      final result = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('username', 'admin')
          .maybeSingle();

      if (result == null) {
        debugPrint('Admin kullanıcı bulunamadı, oluşturuluyor...');

        await Supabase.instance.client.from('users').insert({
          'username': 'admin',
          'password_hash': 'admin',
          'first_name': 'Admin',
          'last_name': 'User',
          'job_title': 'System Administrator',
          'is_admin': true,
          'is_blocked': false,
        });

        debugPrint('Admin kullanıcı başarıyla oluşturuldu');
      } else {
        debugPrint('Admin kullanıcı zaten mevcut');
      }
    } catch (e) {
      debugPrint('Admin kullanıcı oluşturulurken hata: $e');
    }
  }
}
