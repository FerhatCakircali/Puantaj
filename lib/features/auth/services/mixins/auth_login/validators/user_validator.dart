import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/validation/base_validator.dart';

/// Kullanıcı doğrulama işlemlerini yöneten sınıf
class UserValidator extends BaseValidator {
  final SupabaseClient _supabase;

  UserValidator(this._supabase);

  /// Kullanıcının veritabanında var olup olmadığını kontrol eder
  Future<bool> checkUserExists(int userId) async {
    validateId(userId, fieldName: 'Kullanıcı ID');

    final result = await _supabase
        .from('users')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    return result != null;
  }

  /// Kullanıcının bloklu olup olmadığını kontrol eder
  Future<bool> isUserBlocked(int userId) async {
    return executeValidation(
      () async {
        validateId(userId, fieldName: 'Kullanıcı ID');

        final result = await _supabase
            .from('users')
            .select('is_blocked')
            .eq('id', userId)
            .maybeSingle();

        if (result == null) {
          return false;
        }

        return result['is_blocked'] as bool? ?? false;
      },
      false,
      context: 'UserValidator.isUserBlocked',
    );
  }
}
