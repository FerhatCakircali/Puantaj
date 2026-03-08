import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/error_handling/error_handler_mixin.dart';
import '../core/constants/database_constants.dart';
import '../core/constants/business_constants.dart';

/// Merkezi validation servisi
/// Kullanıcı adı ve e-posta kontrollerini tek yerden yönetir
class ValidationService with ErrorHandlerMixin {
  final SupabaseClient _supabase;

  ValidationService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// Kullanıcı adı format validasyonu
  String? validateUsernameFormat(String username) {
    if (username.isEmpty) {
      return 'Kullanıcı adı boş olamaz';
    }

    if (username.length < BusinessConstants.minUsernameLength) {
      return 'Kullanıcı adı en az ${BusinessConstants.minUsernameLength} karakter olmalıdır';
    }

    if (username.length > BusinessConstants.maxUsernameLength) {
      return 'Kullanıcı adı en fazla ${BusinessConstants.maxUsernameLength} karakter olabilir';
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
    return handleError(
      () async {
        final lowercaseUsername = username.toLowerCase();
        debugPrint(
          '🔍 ValidationService: Kullanıcı adı kontrolü: $lowercaseUsername',
        );

        // Users tablosunda kontrol et
        var usersQuery = _supabase
            .from(DatabaseConstants.usersTable)
            .select(DatabaseConstants.userId)
            .eq(DatabaseConstants.userName, lowercaseUsername);

        if (excludeUserId != null) {
          usersQuery = usersQuery.neq(DatabaseConstants.userId, excludeUserId);
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
            .from(DatabaseConstants.workersTable)
            .select(DatabaseConstants.workerId)
            .eq(DatabaseConstants.workerUsername, lowercaseUsername);

        if (excludeWorkerId != null) {
          workersQuery = workersQuery.neq(
            DatabaseConstants.workerId,
            excludeWorkerId,
          );
        }

        final workerResult = await workersQuery.maybeSingle();

        if (workerResult != null) {
          debugPrint(
            '✅ ValidationService: Kullanıcı adı workers tablosunda bulundu',
          );
          return 'Bu kullanıcı adı zaten kullanılıyor';
        }

        debugPrint('ValidationService: Kullanıcı adı kullanılabilir');
        return null;
      },
      'Kullanıcı adı kontrolü sırasında bir hata oluştu',
      context: 'ValidationService.checkUsernameAvailability',
    );
  }

  /// E-posta kullanılabilirlik kontrolü
  /// Hem users hem workers tablosunda kontrol eder
  /// excludeId: Güncelleme işlemlerinde kendi ID'sini hariç tutmak için
  Future<String?> checkEmailAvailability(
    String email, {
    int? excludeUserId,
    int? excludeWorkerId,
  }) async {
    return handleError(
      () async {
        if (email.trim().isEmpty) return null;

        final lowercaseEmail = email.toLowerCase();
        debugPrint('ValidationService: E-posta kontrolü: $lowercaseEmail');

        // Users tablosunda kontrol et
        var usersQuery = _supabase
            .from(DatabaseConstants.usersTable)
            .select(DatabaseConstants.userId)
            .eq('email', lowercaseEmail);

        if (excludeUserId != null) {
          usersQuery = usersQuery.neq(DatabaseConstants.userId, excludeUserId);
        }

        final userResult = await usersQuery.maybeSingle();

        if (userResult != null) {
          debugPrint('ValidationService: E-posta users tablosunda bulundu');
          return 'Bu e-posta adresi zaten kullanılıyor';
        }

        // Workers tablosunda kontrol et
        var workersQuery = _supabase
            .from(DatabaseConstants.workersTable)
            .select(DatabaseConstants.workerId)
            .eq('email', lowercaseEmail);

        if (excludeWorkerId != null) {
          workersQuery = workersQuery.neq(
            DatabaseConstants.workerId,
            excludeWorkerId,
          );
        }

        final workerResult = await workersQuery.maybeSingle();

        if (workerResult != null) {
          debugPrint('ValidationService: E-posta workers tablosunda bulundu');
          return 'Bu e-posta adresi zaten kullanılıyor';
        }

        debugPrint('ValidationService: E-posta kullanılabilir');
        return null;
      },
      'E-posta kontrolü sırasında bir hata oluştu',
      context: 'ValidationService.checkEmailAvailability',
    );
  }

  /// Şifre format validasyonu
  String? validatePasswordFormat(String password) {
    if (password.isEmpty) {
      return 'Şifre boş olamaz';
    }

    if (password.length < BusinessConstants.minPasswordLength) {
      return 'Şifre en az ${BusinessConstants.minPasswordLength} karakter olmalıdır';
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
