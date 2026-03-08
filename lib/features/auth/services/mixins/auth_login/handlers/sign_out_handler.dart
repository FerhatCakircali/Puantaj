import 'package:flutter/foundation.dart';
import '../../../../../../core/user_data_notifier.dart';
import '../../../../../../services/fcm_service.dart';
import '../../../../../../services/notification_service.dart';
import '../../../../../admin/panel/services/activity_log_service.dart';
import '../managers/session_manager.dart';

/// Kullanıcı çıkış işlemlerini yöneten sınıf
class SignOutHandler {
  final SessionManager _sessionManager;
  final ActivityLogService _activityLogService;

  SignOutHandler({
    SessionManager? sessionManager,
    ActivityLogService? activityLogService,
  }) : _sessionManager = sessionManager ?? SessionManager(),
       _activityLogService = activityLogService ?? ActivityLogService();

  /// Çıkış yapma işlemi
  Future<void> signOut(
    Future<Map<String, dynamic>?> Function() loadCurrentUser,
  ) async {
    try {
      await _logActivity(loadCurrentUser);
      await _deleteFCMToken();

      userDataNotifier.value = null;

      await _clearNotifications();
      await _sessionManager.clearSession();
    } catch (e) {
      debugPrint('Çıkış sırasında hata: $e');
    }
  }

  /// Çıkış aktivitesini loglar
  Future<void> _logActivity(
    Future<Map<String, dynamic>?> Function() loadCurrentUser,
  ) async {
    try {
      final user = await loadCurrentUser();
      if (user != null) {
        await _activityLogService.logActivity(
          adminId: user['id'],
          adminUsername: user['username'] ?? '',
          actionType: 'logout',
          targetUserId: user['id'],
          targetUsername: user['username'],
        );
      }
    } catch (e) {
      debugPrint('Çıkış logu kaydedilemedi: $e');
    }
  }

  /// FCM token'ı siler
  Future<void> _deleteFCMToken() async {
    try {
      debugPrint('FCM token siliniyor...');
      await FCMService.instance.deleteToken();
      debugPrint('FCM token silindi');
    } catch (e) {
      debugPrint('FCM token silinemedi (devam ediliyor): $e');
    }
  }

  /// Bildirimleri temizler
  Future<void> _clearNotifications() async {
    try {
      final notificationService = NotificationService();
      await notificationService.clearAllNotificationsOnLogout();
    } catch (e) {
      debugPrint('Bildirim temizleme hatası: $e');
    }
  }
}
