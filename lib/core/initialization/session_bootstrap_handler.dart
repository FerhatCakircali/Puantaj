import '../app_bootstrap.dart';
import '../app_notification_handler.dart';
import '../error_handler.dart';

/// Uygulama açılışında oturum ve bildirim durumunu yöneten sınıf
class SessionBootstrapHandler {
  /// Oturum bilgilerini kontrol eder ve döndürür
  ///
  /// Returns: {isLoggedIn, isAdmin, isWorkerSession}
  static Future<Map<String, dynamic>> bootstrap() async {
    try {
      ErrorHandler.logInfo('Bootstrap', 'Session başlatılıyor...');

      await AppBootstrap.checkInitialNotificationState();

      final workerSession = await AppBootstrap.checkWorkerSession();
      if (workerSession != null) {
        return {'isLoggedIn': false, 'isAdmin': false, 'isWorkerSession': true};
      }

      final userSession = await AppBootstrap.checkUserSession();
      if (userSession == null) {
        return {
          'isLoggedIn': false,
          'isAdmin': false,
          'isWorkerSession': false,
        };
      }

      return {
        'isLoggedIn': true,
        'isAdmin': userSession['isAdmin'] as bool,
        'isWorkerSession': false,
      };
    } catch (e, stack) {
      ErrorHandler.logError('Bootstrap.session', e, stack);
      return {'isLoggedIn': false, 'isAdmin': false, 'isWorkerSession': false};
    }
  }

  /// Initial notification'ı işler
  static Future<void> processInitialNotification() async {
    ErrorHandler.logInfo('Bootstrap', 'Initial notification işleniyor...');
    try {
      await AppNotificationHandler.processInitialNotificationForRouting();
    } catch (e, stack) {
      ErrorHandler.logError('Bootstrap.processNotification', e, stack);
    }
  }
}
