import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/activity_log_helper.dart';
import '../helpers/auth_error_handler.dart';

/// Kullanıcı yönetim sınıfı
///
/// Kullanıcı CRUD işlemlerini yönetir.
class UserManager {
  final ActivityLogHelper _activityLogHelper;
  final Future<Map<String, dynamic>?> Function() loadCurrentUser;
  final Future<String?> Function(String) checkEmailAvailability;

  UserManager({
    required this.loadCurrentUser,
    required this.checkEmailAvailability,
    ActivityLogHelper? activityLogHelper,
  }) : _activityLogHelper = activityLogHelper ?? ActivityLogHelper();

  /// Tüm kullanıcıları getir
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final result = await Supabase.instance.client
          .from('users')
          .select()
          .order('id', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('Kullanıcılar getirilirken hata: $e');
      return [];
    }
  }

  /// Kullanıcı silme
  Future<String?> deleteUser(int userId) async {
    try {
      final targetUser = await _getUserById(userId);

      await Supabase.instance.client.from('users').delete().eq('id', userId);

      await _logUserDeletion(userId, targetUser['username']);

      return null;
    } catch (e) {
      return AuthErrorHandler.userDeletionError(e);
    }
  }

  /// Kullanıcı güncelleme
  Future<String?> updateUser({
    required int userId,
    required String username,
    required String firstName,
    required String lastName,
    required String jobTitle,
    required bool isAdmin,
    String? email,
  }) async {
    try {
      final lowercaseUsername = username.toLowerCase();

      final oldUserData = await _getUserById(userId);
      final oldIsAdmin =
          oldUserData['is_admin'] == 1 || oldUserData['is_admin'] == true;

      final usernameError = await _validateUsername(lowercaseUsername, userId);
      if (usernameError != null) return usernameError;

      if (email != null && email.isNotEmpty) {
        final emailError = await _validateEmail(email, oldUserData);
        if (emailError != null) return emailError;
      }

      await _updateUserData(
        userId,
        lowercaseUsername,
        firstName,
        lastName,
        jobTitle,
        isAdmin,
        email,
      );

      await _logUserUpdate(
        userId,
        lowercaseUsername,
        firstName,
        lastName,
        jobTitle,
        isAdmin,
        oldIsAdmin,
      );

      return null;
    } catch (e) {
      return AuthErrorHandler.userUpdateError(e);
    }
  }

  /// Kullanıcı blok durumu güncelleme
  Future<String?> updateUserBlockedStatus(int userId, bool isBlocked) async {
    try {
      final targetUser = await _getUserById(userId);

      await Supabase.instance.client
          .from('users')
          .update({'is_blocked': isBlocked})
          .eq('id', userId);

      await _logBlockStatusChange(userId, targetUser['username'], isBlocked);

      return null;
    } catch (e) {
      return AuthErrorHandler.blockStatusUpdateError(e);
    }
  }

  /// Kullanıcı profil güncelleme (admin tarafından)
  Future<String?> updateUserProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String jobTitle,
  }) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({
            'first_name': firstName,
            'last_name': lastName,
            'job_title': jobTitle,
          })
          .eq('id', int.parse(userId));

      return null;
    } catch (e) {
      return AuthErrorHandler.profileUpdateError(e);
    }
  }

  /// Kullanıcı blok durumu değiştirme
  Future<String?> toggleUserBlockStatus(String userId, bool isBlocked) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'is_blocked': isBlocked})
          .eq('id', int.parse(userId));

      return null;
    } catch (e) {
      return AuthErrorHandler.blockStatusUpdateError(e);
    }
  }

  /// Admin yetkisi değiştirme
  Future<String?> toggleUserAdminStatus(String userId, bool isAdmin) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'is_admin': isAdmin})
          .eq('id', int.parse(userId));

      return null;
    } catch (e) {
      return AuthErrorHandler.adminStatusChangeError(e);
    }
  }

  /// Kullanıcıyı ID'ye göre getirir
  Future<Map<String, dynamic>> _getUserById(int userId) async {
    return await Supabase.instance.client
        .from('users')
        .select()
        .eq('id', userId)
        .single();
  }

  /// Kullanıcı adını doğrular
  Future<String?> _validateUsername(String username, int userId) async {
    final existingUsers = await Supabase.instance.client
        .from('users')
        .select('id')
        .eq('username', username)
        .neq('id', userId)
        .maybeSingle();

    if (existingUsers != null) {
      return 'Bu kullanıcı adı zaten kullanılıyor';
    }

    final existingWorkers = await Supabase.instance.client
        .from('workers')
        .select('id')
        .eq('username', username)
        .maybeSingle();

    if (existingWorkers != null) {
      return 'Bu kullanıcı adı zaten kullanılıyor';
    }

    return null;
  }

  /// Email'i doğrular
  Future<String?> _validateEmail(
    String email,
    Map<String, dynamic> oldUserData,
  ) async {
    final oldEmail = oldUserData['email'] as String?;

    if (oldEmail?.toLowerCase() != email.toLowerCase()) {
      return await checkEmailAvailability(email);
    }

    return null;
  }

  /// Kullanıcı verilerini günceller
  Future<void> _updateUserData(
    int userId,
    String username,
    String firstName,
    String lastName,
    String jobTitle,
    bool isAdmin,
    String? email,
  ) async {
    final updateData = {
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'job_title': jobTitle,
      'is_admin': isAdmin ? 1 : 0,
    };

    if (email != null && email.isNotEmpty) {
      updateData['email'] = email.toLowerCase();
    }

    await Supabase.instance.client
        .from('users')
        .update(updateData)
        .eq('id', userId);
  }

  /// Kullanıcı silme işlemini loglar
  Future<void> _logUserDeletion(int userId, String username) async {
    final currentUser = await loadCurrentUser();
    if (currentUser != null) {
      await _activityLogHelper.logUserDeletion(
        adminId: currentUser['id'],
        adminUsername: currentUser['username'] ?? '',
        targetUserId: userId,
        targetUsername: username,
      );
    }
  }

  /// Kullanıcı güncelleme işlemini loglar
  Future<void> _logUserUpdate(
    int userId,
    String username,
    String firstName,
    String lastName,
    String jobTitle,
    bool isAdmin,
    bool oldIsAdmin,
  ) async {
    final currentUser = await loadCurrentUser();
    if (currentUser != null) {
      await _activityLogHelper.logUserUpdate(
        adminId: currentUser['id'],
        adminUsername: currentUser['username'] ?? '',
        targetUserId: userId,
        targetUsername: username,
        details: {
          'username': username,
          'first_name': firstName,
          'last_name': lastName,
          'job_title': jobTitle,
          'is_admin': isAdmin,
        },
      );

      if (oldIsAdmin != isAdmin) {
        await _activityLogHelper.logAdminStatusChange(
          adminId: currentUser['id'],
          adminUsername: currentUser['username'] ?? '',
          targetUserId: userId,
          targetUsername: username,
          isGranted: isAdmin,
        );
      }
    }
  }

  /// Blok durumu değişikliğini loglar
  Future<void> _logBlockStatusChange(
    int userId,
    String username,
    bool isBlocked,
  ) async {
    final currentUser = await loadCurrentUser();
    if (currentUser != null) {
      await _activityLogHelper.logBlockStatusChange(
        adminId: currentUser['id'],
        adminUsername: currentUser['username'] ?? '',
        targetUserId: userId,
        targetUsername: username,
        isBlocked: isBlocked,
      );
    }
  }
}
