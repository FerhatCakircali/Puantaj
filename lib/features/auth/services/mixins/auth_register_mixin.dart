import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/services/password_hasher.dart';

mixin AuthRegisterMixin {
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

      final usernameError = validateUsername(lowercaseUsername);
      if (usernameError != null) {
        return usernameError;
      }

      final usernameAvailability = await checkUsernameAvailability(
        lowercaseUsername,
      );
      if (usernameAvailability != null) {
        return usernameAvailability;
      }

      // Email kontrolü (zorunlu)
      if (email == null || email.isEmpty) {
        return 'Email adresi gerekli';
      }

      final emailAvailability = await checkEmailAvailability(email);
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
          return 'Bu email adresi zaten kullanılıyor';
        }
      }
      return 'Bir hata oluştu';
    }
  }

  /// Kullanıcı adı validasyonu
  String? validateUsername(String username) {
    if (username.isEmpty) {
      return 'Kullanıcı adı boş olamaz.';
    }

    if (username.length < 3) {
      return 'Kullanıcı adı en az 3 karakter olmalıdır.';
    }

    if (username.length > 30) {
      return 'Kullanıcı adı en fazla 30 karakter olabilir.';
    }

    final validUsernameRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!validUsernameRegex.hasMatch(username)) {
      return 'Kullanıcı adı sadece İngilizce harfler (A-Z) ve sayılardan (0-9) oluşmalıdır.';
    }

    return null;
  }

  /// Kullanıcı adı kullanılabilirlik kontrolü (hem users hem workers tablosunda)
  Future<String?> checkUsernameAvailability(String username) async {
    try {
      final lowercaseUsername = username.toLowerCase();

      // Users tablosunda kontrol et
      final userResult = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('username', lowercaseUsername)
          .maybeSingle();

      if (userResult != null) {
        return 'Bu kullanıcı adı zaten kullanılıyor';
      }

      // Workers tablosunda da kontrol et
      final workerResult = await Supabase.instance.client
          .from('workers')
          .select('id')
          .eq('username', lowercaseUsername)
          .maybeSingle();

      if (workerResult != null) {
        return 'Bu kullanıcı adı zaten kullanılıyor';
      }

      return null;
    } catch (e) {
      debugPrint('Kullanıcı adı kontrolü hatası: $e');
      return 'Kullanıcı adı kontrolü sırasında bir hata oluştu';
    }
  }

  /// Email kullanılabilirlik kontrolü (hem users hem workers tablosunda)
  Future<String?> checkEmailAvailability(String email) async {
    try {
      final lowercaseEmail = email.toLowerCase();

      // Users tablosunda kontrol et
      final userResult = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('email', lowercaseEmail)
          .maybeSingle();

      if (userResult != null) {
        return 'Bu email adresi zaten kullanılıyor';
      }

      // Workers tablosunda da kontrol et
      final workerResult = await Supabase.instance.client
          .from('workers')
          .select('id')
          .eq('email', lowercaseEmail)
          .maybeSingle();

      if (workerResult != null) {
        return 'Bu email adresi zaten kullanılıyor';
      }

      return null;
    } catch (e) {
      debugPrint('Email kontrolü hatası: $e');
      return 'Email kontrolü sırasında bir hata oluştu';
    }
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
          'password_hash': 'admin123',
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
