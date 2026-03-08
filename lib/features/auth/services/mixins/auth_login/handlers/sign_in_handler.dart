import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../../../../core/user_data_notifier.dart';
import '../../../../../../services/fcm_service.dart';
import '../../../../../../data/services/local_storage_service.dart';
import '../../../../../worker/services/worker_notification_listener_service.dart';
import '../../../../../admin/panel/services/activity_log_service.dart';
import '../managers/session_manager.dart';
import 'password_migration_handler.dart';

/// Kullanıcı giriş işlemlerini yöneten sınıf
class SignInHandler {
  final SessionManager _sessionManager;
  final PasswordMigrationHandler _passwordHandler;
  final ActivityLogService _activityLogService;

  SignInHandler({
    SessionManager? sessionManager,
    PasswordMigrationHandler? passwordHandler,
    ActivityLogService? activityLogService,
  }) : _sessionManager = sessionManager ?? SessionManager(),
       _passwordHandler = passwordHandler ?? PasswordMigrationHandler(),
       _activityLogService = activityLogService ?? ActivityLogService();

  /// Giriş yapma işlemi
  Future<String?> signIn(String username, String password) async {
    try {
      final lowercaseUsername = username.toLowerCase();

      final result = await _fetchUser(lowercaseUsername);
      if (result == null) {
        userDataNotifier.value = null;
        return 'Kullanıcı adı veya şifre yanlış.';
      }

      final isPasswordValid = await _passwordHandler.validateAndMigratePassword(
        password: password,
        storedHash: result['password_hash'] as String,
        userId: result['id'] as int,
      );

      if (!isPasswordValid) {
        userDataNotifier.value = null;
        return 'Kullanıcı adı veya şifre yanlış.';
      }

      final isBlocked = result['is_blocked'] as bool;
      if (isBlocked) {
        userDataNotifier.value = null;
        return 'Hesabınız yönetici tarafından onaylanana kadar giriş yapamazsınız.';
      }

      await _clearWorkerSession();

      final userId = result['id'] as int;
      await _sessionManager.setUserId(userId);
      await _loadCurrentUser();

      await _saveFCMToken(userId);
      await _logActivity(userId, lowercaseUsername);

      return null;
    } catch (e) {
      debugPrint('Giriş sırasında hata: $e');
      return _handleSignInError(e);
    }
  }

  /// Kullanıcıyı veritabanından getirir
  Future<Map<String, dynamic>?> _fetchUser(String username) async {
    return await Supabase.instance.client
        .from('users')
        .select('*, is_blocked')
        .eq('username', username)
        .maybeSingle();
  }

  /// Çalışan oturumunu temizler
  Future<void> _clearWorkerSession() async {
    try {
      debugPrint('Kullanıcı girişi - Çalışan oturumu temizleniyor...');

      await WorkerNotificationListenerService.instance.stopListening();
      debugPrint('Çalışan bildirim dinleyicisi durduruldu');

      await LocalStorageService.instance.clearWorkerSession();
      debugPrint('Çalışan oturumu temizlendi');
    } catch (e) {
      debugPrint('Çalışan oturumu temizlenirken hata (devam ediliyor): $e');
    }
  }

  /// FCM token'ı kaydeder
  Future<void> _saveFCMToken(int userId) async {
    try {
      debugPrint('FCM token kaydediliyor (User: $userId)...');
      await FCMService.instance.saveTokenForUser(userId);
      debugPrint('FCM token kaydedildi');
    } catch (e) {
      debugPrint('FCM token kaydedilemedi (devam ediliyor): $e');
    }
  }

  /// Giriş aktivitesini loglar
  Future<void> _logActivity(int userId, String username) async {
    try {
      await _activityLogService.logActivity(
        adminId: userId,
        adminUsername: username,
        actionType: 'login',
        targetUserId: userId,
        targetUsername: username,
      );
    } catch (e) {
      debugPrint('Giriş logu kaydedilemedi: $e');
    }
  }

  /// Mevcut kullanıcı bilgilerini yükler
  Future<Map<String, dynamic>?> _loadCurrentUser() async {
    try {
      final userId = await _sessionManager.getUserId();
      if (userId == null) {
        userDataNotifier.value = null;
        return null;
      }

      final result = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      userDataNotifier.value = result;
      return result;
    } catch (e) {
      debugPrint('Kullanıcı bilgileri alınırken hata: $e');
      userDataNotifier.value = null;
      return null;
    }
  }

  /// Giriş hatalarını işler
  String _handleSignInError(Object e) {
    if (e is SocketException || e is http.ClientException) {
      userDataNotifier.value = null;
      return 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
    } else if (e is PostgrestException) {
      debugPrint(
        'PostgrestException detayları: Code=${e.code}, Message=${e.message}, Details=${e.details}',
      );
      if (e.code == '42P01') {
        return 'Veritabanı tabloları oluşturulmamış. Lütfen yöneticinize başvurun.';
      }
      return 'Veritabanı hatası: ${e.message}';
    }

    userDataNotifier.value = null;
    return 'Giriş sırasında bir hata oluştu: ${e.toString()}';
  }
}
