import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/local_storage_service.dart';
import '../services/auth_service.dart';
import '../features/worker/services/worker_notification_listener_service.dart';
import 'error_handler.dart';
import 'user_data_notifier.dart';

/// Uygulama başlatma mantığı
class AppBootstrap {
  /// Başlangıçta bildirim durumunu kontrol eder
  static Future<void> checkInitialNotificationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final launchedFromNotification =
          prefs.getBool('launched_from_notification') ?? false;
      final notificationNeedsHandling =
          prefs.getBool('notification_needs_handling') ?? false;
      final payload = prefs.getString('last_notification_payload');

      ErrorHandler.logDebug(
        'Bootstrap.notification',
        'Bildirim durumu kontrol ediliyor',
        {
          'launchedFromNotification': launchedFromNotification,
          'notificationNeedsHandling': notificationNeedsHandling,
          'hasPayload': payload != null,
        },
      );

      if (launchedFromNotification || notificationNeedsHandling) {
        ErrorHandler.logInfo(
          'Bootstrap.notification',
          'Bildirim tespit edildi',
        );
      }
    } catch (e, stack) {
      ErrorHandler.logError('Bootstrap.checkNotificationState', e, stack);
    }
  }

  /// Çalışan oturumunu kontrol eder ve yükler
  static Future<Map<String, dynamic>?> checkWorkerSession() async {
    try {
      final localStorage = LocalStorageService.instance;
      final workerSession = await localStorage.getWorkerSession();

      if (workerSession != null) {
        ErrorHandler.logSuccess('Bootstrap', 'Çalışan oturumu bulundu', {
          'workerId': workerSession['workerId'],
        });

        // Kullanıcı oturumunu temizle (varsa)
        try {
          final authService = AuthService();
          final user = await authService.currentUser;
          if (user != null) {
            debugPrint(
              '🧹 Çalışan oturumu aktif - Kullanıcı oturumu temizleniyor...',
            );
            await authService.signOut();
            debugPrint('Kullanıcı oturumu temizlendi');
          }
        } catch (e) {
          debugPrint(
            '⚠️ Kullanıcı oturumu temizlenirken hata (devam ediliyor): $e',
          );
        }

        // Çalışan bilgilerini userDataNotifier'a yükle
        userDataNotifier.value = {
          'id': workerSession['workerId'],
          'username': workerSession['username'],
          'full_name': workerSession['fullName'],
          'is_admin': false,
        };

        return workerSession;
      }

      return null;
    } catch (e, stack) {
      ErrorHandler.logError('Bootstrap.checkWorkerSession', e, stack);
      return null;
    }
  }

  /// Kullanıcı oturumunu kontrol eder ve yükler
  static Future<Map<String, dynamic>?> checkUserSession() async {
    try {
      final authService = AuthService();
      final user = await authService.currentUser;

      if (user == null) {
        ErrorHandler.logInfo('Bootstrap', 'Kayıtlı oturum bulunamadı');
        return null;
      }

      // Kullanıcı oturumu var - çalışan oturumunu ve bildirim dinleyicisini temizle
      try {
        debugPrint(
          '🧹 Kullanıcı oturumu aktif - Çalışan oturumu temizleniyor...',
        );

        await WorkerNotificationListenerService.instance.stopListening();
        await LocalStorageService.instance.clearWorkerSession();

        debugPrint('Çalışan oturumu ve bildirim dinleyicisi temizlendi');
      } catch (e) {
        debugPrint(
          '⚠️ Çalışan oturumu temizlenirken hata (devam ediliyor): $e',
        );
      }

      final userId = user['id'];
      ErrorHandler.logSuccess('Bootstrap', 'Kayıtlı oturum bulundu', {
        'userId': userId,
      });

      final dynamic isAdminValue = user['is_admin'];
      final String username = (user['username'] as String).toLowerCase();
      bool isAdmin = false;

      if (isAdminValue is int) {
        isAdmin = isAdminValue == 1;
      } else if (isAdminValue is bool) {
        isAdmin = isAdminValue;
      }

      if (username == 'admin') {
        isAdmin = true;
      }

      ErrorHandler.logInfo('Bootstrap', 'Oturum geri yüklendi', {
        'isAdmin': isAdmin,
      });

      return {'user': user, 'isAdmin': isAdmin};
    } catch (e, stack) {
      ErrorHandler.logError('Bootstrap.checkUserSession', e, stack);
      return null;
    }
  }

  /// Admin durumunu kontrol eder
  static bool checkAdminStatus(Map<String, dynamic>? userData) {
    if (userData == null) {
      return false;
    }

    try {
      final dynamic isAdminValue = userData['is_admin'];
      final String username = (userData['username'] as String).toLowerCase();

      ErrorHandler.logDebug('AdminCheck', 'Admin kontrolü yapılıyor', {
        'isAdminValue': isAdminValue,
        'isAdminType': isAdminValue.runtimeType.toString(),
        'username': username,
      });

      bool isAdmin = false;

      if (isAdminValue is int) {
        isAdmin = isAdminValue == 1;
      } else if (isAdminValue is bool) {
        isAdmin = isAdminValue;
      }

      if (username == 'admin') {
        isAdmin = true;
      }

      return isAdmin;
    } catch (e, stack) {
      ErrorHandler.logError('AdminCheck', e, stack);
      return false;
    }
  }
}
