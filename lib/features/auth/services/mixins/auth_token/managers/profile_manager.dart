import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../services/validation_service.dart';
import '../../../../../../core/di/service_locator.dart';
import '../helpers/activity_log_helper.dart';
import '../helpers/auth_error_handler.dart';

/// Profil yönetim sınıfı
///
/// Kullanıcı profil işlemlerini yönetir.
class ProfileManager {
  final ActivityLogHelper _activityLogHelper;
  final Future<int?> Function() getUserId;
  final Future<Map<String, dynamic>?> Function() loadCurrentUser;
  final String? Function(String) validateUsername;
  final ValidationService _validationService = getIt<ValidationService>();

  ProfileManager({
    required this.getUserId,
    required this.loadCurrentUser,
    required this.validateUsername,
    ActivityLogHelper? activityLogHelper,
  }) : _activityLogHelper = activityLogHelper ?? ActivityLogHelper();

  /// Profil güncelleme
  ///
  /// Kullanıcının ad, soyad, iş unvanı ve email bilgilerini günceller.
  Future<String?> updateProfile(
    String firstName,
    String lastName,
    String jobTitle, {
    String? email,
  }) async {
    final userId = await getUserId();
    if (userId == null) return 'Oturum açmanız gerekiyor.';

    try {
      if (email != null && email.isNotEmpty) {
        final emailError = await _validateEmailChange(userId, email);
        if (emailError != null) return emailError;
      }

      await _updateProfileData(userId, firstName, lastName, jobTitle, email);
      await _logProfileUpdate(userId, firstName, lastName, jobTitle, email);

      return null;
    } catch (e) {
      return AuthErrorHandler.profileUpdateError(e);
    }
  }

  /// Kullanıcı adı güncelleme
  ///
  /// Kullanıcı adını doğrular ve günceller.
  Future<String?> updateUsername(String newUsername) async {
    final userId = await getUserId();
    if (userId == null) return 'Oturum açmanız gerekiyor.';

    final lowercaseUsername = newUsername.toLowerCase();

    final usernameError = validateUsername(lowercaseUsername);
    if (usernameError != null) return usernameError;

    try {
      final availabilityError = await _validationService
          .checkUsernameAvailability(lowercaseUsername, excludeUserId: userId);
      if (availabilityError != null) return availabilityError;

      await Supabase.instance.client
          .from('users')
          .update({'username': lowercaseUsername})
          .eq('id', userId);

      await loadCurrentUser();
      return null;
    } catch (e) {
      return AuthErrorHandler.usernameUpdateError(e);
    }
  }

  /// Email değişikliğini doğrular
  Future<String?> _validateEmailChange(int userId, String email) async {
    final currentUser = await loadCurrentUser();
    final currentEmail = currentUser?['email'] as String?;

    if (currentEmail?.toLowerCase() != email.toLowerCase()) {
      return await _validationService.checkEmailAvailability(
        email,
        excludeUserId: userId,
      );
    }

    return null;
  }

  /// Profil verilerini günceller
  Future<void> _updateProfileData(
    int userId,
    String firstName,
    String lastName,
    String jobTitle,
    String? email,
  ) async {
    final updateData = {
      'first_name': firstName,
      'last_name': lastName,
      'job_title': jobTitle,
    };

    if (email != null && email.isNotEmpty) {
      updateData['email'] = email.toLowerCase();
    }

    await Supabase.instance.client
        .from('users')
        .update(updateData)
        .eq('id', userId);

    await loadCurrentUser();
  }

  /// Profil güncellemesini loglar
  Future<void> _logProfileUpdate(
    int userId,
    String firstName,
    String lastName,
    String jobTitle,
    String? email,
  ) async {
    final currentUser = await loadCurrentUser();
    if (currentUser != null) {
      await _activityLogHelper.logProfileUpdate(
        userId: userId,
        username: currentUser['username'] ?? '',
        details: {
          'first_name': firstName,
          'last_name': lastName,
          'job_title': jobTitle,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );
    }
  }
}
