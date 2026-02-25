import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'error_handler.dart';

/// Uygulama bildirim işleme mantığı
class AppNotificationHandler {
  /// Uygulama açılışında bildirim payload'ını işle
  static Future<void> processInitialNotificationForRouting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final needsHandling =
          prefs.getBool('notification_needs_handling') ?? false;

      if (!needsHandling) {
        ErrorHandler.logDebug(
          'ProcessInitialNotification',
          'Bildirim işleme gerekmiyor',
        );
        return;
      }

      ErrorHandler.logInfo(
        'ProcessInitialNotification',
        'Başlangıç bildirimi tespit edildi',
      );
      final payload = prefs.getString('last_notification_payload');

      if (payload != null && payload.isNotEmpty) {
        final notificationService = NotificationService();
        await notificationService.handleNotificationTap(payload);
        ErrorHandler.logSuccess(
          'ProcessInitialNotification',
          'Bildirim payload işlendi',
          {'payload': payload},
        );
      } else {
        ErrorHandler.logWarning(
          'ProcessInitialNotification',
          'Bildirim payload bulunamadı veya boş',
        );
      }
    } catch (e, stack) {
      ErrorHandler.logError('ProcessInitialNotification', e, stack);
    } finally {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notification_needs_handling', false);
      } catch (e, stack) {
        ErrorHandler.logError('ProcessInitialNotification.clearFlag', e, stack);
      }
    }
  }

  /// Bildirim mesajını merkezi olarak işle
  static Future<void> processNotificationMessage(String message) async {
    try {
      final notificationService = NotificationService();
      await notificationService.handleNotificationTap(message);
      ErrorHandler.logSuccess(
        'ProcessNotificationMessage',
        'Bildirim payload işlendi',
        {'message': message},
      );

      ErrorHandler.logSuccess(
        'ProcessNotificationMessage',
        'Bildirim yönlendirmesi tamamlandı',
      );
    } catch (e, stack) {
      ErrorHandler.logError('ProcessNotificationMessage', e, stack);
      rethrow;
    }
  }
}
