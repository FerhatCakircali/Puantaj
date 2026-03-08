import '../../../../../admin/panel/services/activity_log_service.dart';

/// Aktivite log yardımcı sınıfı
///
/// Kullanıcı işlemlerini loglama işlemlerini yönetir.
class ActivityLogHelper {
  final _activityLogService = ActivityLogService();

  /// Şifre değişikliği loglar
  Future<void> logPasswordChange({
    required int userId,
    required String username,
  }) async {
    await _activityLogService.logActivity(
      adminId: userId,
      adminUsername: username,
      actionType: 'password_changed',
      targetUserId: userId,
      targetUsername: username,
    );
  }

  /// Profil güncelleme loglar
  Future<void> logProfileUpdate({
    required int userId,
    required String username,
    required Map<String, dynamic> details,
  }) async {
    await _activityLogService.logActivity(
      adminId: userId,
      adminUsername: username,
      actionType: 'profile_updated',
      targetUserId: userId,
      targetUsername: username,
      details: details,
    );
  }

  /// Kullanıcı silme loglar
  Future<void> logUserDeletion({
    required int adminId,
    required String adminUsername,
    required int targetUserId,
    required String targetUsername,
  }) async {
    await _activityLogService.logActivity(
      adminId: adminId,
      adminUsername: adminUsername,
      actionType: 'user_deleted',
      targetUserId: targetUserId,
      targetUsername: targetUsername,
    );
  }

  /// Kullanıcı güncelleme loglar
  Future<void> logUserUpdate({
    required int adminId,
    required String adminUsername,
    required int targetUserId,
    required String targetUsername,
    required Map<String, dynamic> details,
  }) async {
    await _activityLogService.logActivity(
      adminId: adminId,
      adminUsername: adminUsername,
      actionType: 'user_updated',
      targetUserId: targetUserId,
      targetUsername: targetUsername,
      details: details,
    );
  }

  /// Admin yetkisi değişikliği loglar
  Future<void> logAdminStatusChange({
    required int adminId,
    required String adminUsername,
    required int targetUserId,
    required String targetUsername,
    required bool isGranted,
  }) async {
    await _activityLogService.logActivity(
      adminId: adminId,
      adminUsername: adminUsername,
      actionType: isGranted ? 'admin_granted' : 'admin_revoked',
      targetUserId: targetUserId,
      targetUsername: targetUsername,
    );
  }

  /// Kullanıcı blok durumu değişikliği loglar
  Future<void> logBlockStatusChange({
    required int adminId,
    required String adminUsername,
    required int targetUserId,
    required String targetUsername,
    required bool isBlocked,
  }) async {
    await _activityLogService.logActivity(
      adminId: adminId,
      adminUsername: adminUsername,
      actionType: isBlocked ? 'user_blocked' : 'user_unblocked',
      targetUserId: targetUserId,
      targetUsername: targetUsername,
    );
  }
}
