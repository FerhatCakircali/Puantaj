import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Merkezi validation servisi
/// Kullanıcı adı ve e-posta kontrollerini tek yerden yönetir
class ValidationService {
  static final ValidationService _instance = ValidationService._internal();
  factory ValidationService() => _instance;
  ValidationService._internal();

  static ValidationService get instance => _instance;

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Kullanıcı adı format validasyonu
  String? validateUsernameFormat(String username) {
    if (username.isEmpty) {
      return 'Kullanıcı adı boş olamaz';
    }

    if (username.length < 3) {
      return 'Kullanıcı adı en az 3 karakter olmalıdır';
    }

    if (username.length > 30) {
      return 'Kullanıcı adı en fazla 30 karakter olabilir';
    }

    final validUsernameRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!validUsernameRegex.hasMatch(username)) {
      return 'Kullanıcı adı sadece İngilizce harfler (A-Z) ve sayılardan (0-9) oluşmalıdır';
    }

    return null;
  }

  /// E-posta format validasyonu
  String? validateEmailFormat(String email) {
    if (email.isEmpty) {
      return 'E-posta adresi boş olamaz';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return 'Geçerli bir e-posta adresi girin';
    }

    return null;
  }

  /// Kullanıcı adı kullanılabilirlik kontrolü
  /// Hem users hem workers tablosunda kontrol eder
  /// excludeId: Güncelleme işlemlerinde kendi ID'sini hariç tutmak için
  Future<String?> checkUsernameAvailability(
    String username, {
    int? excludeUserId,
    int? excludeWorkerId,
  }) async {
    try {
      final lowercaseUsername = username.toLowerCase();
      debugPrint(
        '🔍 ValidationService: Kullanıcı adı kontrolü: $lowercaseUsername',
      );

      // Users tablosunda kontrol et
      var usersQuery = _supabase
          .from('users')
          .select('id')
          .eq('username', lowercaseUsername);

      if (excludeUserId != null) {
        usersQuery = usersQuery.neq('id', excludeUserId);
      }

      final userResult = await usersQuery.maybeSingle();

      if (userResult != null) {
        debugPrint(
          '✅ ValidationService: Kullanıcı adı users tablosunda bulundu',
        );
        return 'Bu kullanıcı adı zaten kullanılıyor';
      }

      // Workers tablosunda kontrol et
      var workersQuery = _supabase
          .from('workers')
          .select('id')
          .eq('username', lowercaseUsername);

      if (excludeWorkerId != null) {
        workersQuery = workersQuery.neq('id', excludeWorkerId);
      }

      final workerResult = await workersQuery.maybeSingle();

      if (workerResult != null) {
        debugPrint(
          '✅ ValidationService: Kullanıcı adı workers tablosunda bulundu',
        );
        return 'Bu kullanıcı adı zaten kullanılıyor';
      }

      debugPrint('✅ ValidationService: Kullanıcı adı kullanılabilir');
      return null;
    } catch (e) {
      debugPrint('❌ ValidationService: Kullanıcı adı kontrolü hatası: $e');
      return 'Kullanıcı adı kontrolü sırasında bir hata oluştu';
    }
  }

  /// E-posta kullanılabilirlik kontrolü
  /// Hem users hem workers tablosunda kontrol eder
  /// excludeId: Güncelleme işlemlerinde kendi ID'sini hariç tutmak için
  Future<String?> checkEmailAvailability(
    String email, {
    int? excludeUserId,
    int? excludeWorkerId,
  }) async {
    try {
      if (email.trim().isEmpty) return null;

      final lowercaseEmail = email.toLowerCase();
      debugPrint('🔍 ValidationService: E-posta kontrolü: $lowercaseEmail');

      // Users tablosunda kontrol et
      var usersQuery = _supabase
          .from('users')
          .select('id')
          .eq('email', lowercaseEmail);

      if (excludeUserId != null) {
        usersQuery = usersQuery.neq('id', excludeUserId);
      }

      final userResult = await usersQuery.maybeSingle();

      if (userResult != null) {
        debugPrint('✅ ValidationService: E-posta users tablosunda bulundu');
        return 'Bu e-posta adresi zaten kullanılıyor';
      }

      // Workers tablosunda kontrol et
      var workersQuery = _supabase
          .from('workers')
          .select('id')
          .eq('email', lowercaseEmail);

      if (excludeWorkerId != null) {
        workersQuery = workersQuery.neq('id', excludeWorkerId);
      }

      final workerResult = await workersQuery.maybeSingle();

      if (workerResult != null) {
        debugPrint('✅ ValidationService: E-posta workers tablosunda bulundu');
        return 'Bu e-posta adresi zaten kullanılıyor';
      }

      debugPrint('✅ ValidationService: E-posta kullanılabilir');
      return null;
    } catch (e) {
      debugPrint('❌ ValidationService: E-posta kontrolü hatası: $e');
      return 'E-posta kontrolü sırasında bir hata oluştu';
    }
  }

  /// Şifre format validasyonu
  String? validatePasswordFormat(String password) {
    if (password.isEmpty) {
      return 'Şifre boş olamaz';
    }

    if (password.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }

    return null;
  }

  /// Şifre eşleşme kontrolü
  String? validatePasswordMatch(String password, String confirmPassword) {
    if (password != confirmPassword) {
      return 'Şifreler eşleşmiyor';
    }
    return null;
  }
}
