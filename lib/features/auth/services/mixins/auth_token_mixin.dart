import 'auth_token/helpers/activity_log_helper.dart';
import 'auth_token/managers/admin_manager.dart';
import 'auth_token/managers/password_manager.dart';
import 'auth_token/managers/profile_manager.dart';
import 'auth_token/managers/user_manager.dart';

/// Auth token işlemleri mixin'i
///
/// Kullanıcı kimlik doğrulama ve yetkilendirme işlemlerini koordine eder.
mixin AuthTokenMixin {
  Future<int?> getUserId();
  Future<Map<String, dynamic>?> loadCurrentUser();
  String? validateUsername(String username);
  Future<String?> checkUsernameAvailability(String username);
  Future<String?> checkEmailAvailability(String email);

  late final ActivityLogHelper _activityLogHelper = ActivityLogHelper();

  late final PasswordManager _passwordManager = PasswordManager(
    getUserId: getUserId,
    loadCurrentUser: loadCurrentUser,
    activityLogHelper: _activityLogHelper,
  );

  late final ProfileManager _profileManager = ProfileManager(
    getUserId: getUserId,
    loadCurrentUser: loadCurrentUser,
    validateUsername: validateUsername,
    activityLogHelper: _activityLogHelper,
  );

  late final UserManager _userManager = UserManager(
    loadCurrentUser: loadCurrentUser,
    checkEmailAvailability: checkEmailAvailability,
    activityLogHelper: _activityLogHelper,
  );

  late final AdminManager _adminManager = AdminManager(
    loadCurrentUser: loadCurrentUser,
  );

  /// Şifre değiştirme
  Future<String?> changePassword(String currentPassword, String newPassword) =>
      _passwordManager.changePassword(currentPassword, newPassword);

  /// Profil güncelleme
  Future<String?> updateProfile(
    String firstName,
    String lastName,
    String jobTitle, {
    String? email,
  }) => _profileManager.updateProfile(
    firstName,
    lastName,
    jobTitle,
    email: email,
  );

  /// Kullanıcı adı güncelleme
  Future<String?> updateUsername(String newUsername) =>
      _profileManager.updateUsername(newUsername);

  /// Admin kontrolü
  Future<bool> isAdmin() => _adminManager.isAdmin();

  /// Tüm kullanıcıları getir
  Future<List<Map<String, dynamic>>> getAllUsers() =>
      _userManager.getAllUsers();

  /// Kullanıcı silme
  Future<String?> deleteUser(int userId) => _userManager.deleteUser(userId);

  /// Kullanıcı güncelleme
  Future<String?> updateUser({
    required int userId,
    required String username,
    required String firstName,
    required String lastName,
    required String jobTitle,
    required bool isAdmin,
    String? email,
  }) => _userManager.updateUser(
    userId: userId,
    username: username,
    firstName: firstName,
    lastName: lastName,
    jobTitle: jobTitle,
    isAdmin: isAdmin,
    email: email,
  );

  /// Kullanıcı blok durumu güncelleme
  Future<String?> updateUserBlockedStatus(int userId, bool isBlocked) =>
      _userManager.updateUserBlockedStatus(userId, isBlocked);

  /// Kullanıcı profil güncelleme (admin tarafından)
  Future<String?> updateUserProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String jobTitle,
  }) => _userManager.updateUserProfile(
    userId: userId,
    firstName: firstName,
    lastName: lastName,
    jobTitle: jobTitle,
  );

  /// Kullanıcı blok durumu değiştirme
  Future<String?> toggleUserBlockStatus(String userId, bool isBlocked) =>
      _userManager.toggleUserBlockStatus(userId, isBlocked);

  /// Admin yetkisi değiştirme
  Future<String?> toggleUserAdminStatus(String userId, bool isAdmin) =>
      _userManager.toggleUserAdminStatus(userId, isAdmin);

  /// System Administrator kontrolü
  bool isSystemAdmin(Map<String, dynamic> user) =>
      _adminManager.isSystemAdmin(user);

  /// Mevcut kullanıcının system admin olup olmadığını kontrol et
  Future<bool> isCurrentUserSystemAdmin() =>
      _adminManager.isCurrentUserSystemAdmin();
}
