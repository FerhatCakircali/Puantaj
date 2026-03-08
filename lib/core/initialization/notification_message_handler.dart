import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../app_notification_handler.dart';
import '../error_handler.dart';

/// Platform mesajlarını ve bildirim tıklamalarını işleyen sınıf
class NotificationMessageHandler {
  bool _isHandlingNotification = false;

  /// Platform'dan gelen mesajı işler
  Future<String> handlePlatformMessage(String? message) async {
    ErrorHandler.logDebug('PlatformMessage', 'Android\'den mesaj alındı', {
      'message': message,
    });

    if (message == null) {
      return 'Mesaj boş';
    }

    try {
      if (!_isHandlingNotification) {
        _isHandlingNotification = true;
        await _processNotificationMessage(message);
        Future.delayed(const Duration(seconds: 2), () {
          _isHandlingNotification = false;
        });
      }
    } catch (e, stack) {
      ErrorHandler.logError('PlatformMessage.handle', e, stack);
      _isHandlingNotification = false;
    }

    return 'Mesaj işlendi';
  }

  /// Bildirim mesajını işler
  Future<void> _processNotificationMessage(String message) async {
    try {
      await AppNotificationHandler.processNotificationMessage(message);
    } catch (e, stack) {
      ErrorHandler.logError('ProcessNotificationMessage', e, stack);
    }
  }

  /// Bildirim tıklamasını işler
  Future<void> handleNotificationClick(String payload) async {
    try {
      debugPrint('Notification click işleniyor: $payload');
      await AppNotificationHandler.processNotificationMessage(payload);
    } catch (e, stack) {
      ErrorHandler.logError('HandleNotificationClick', e, stack);
    }
  }

  /// Bildirim hatası durumunda fallback davranışı
  static Future<void> handleNotificationError(GoRouter? router) async {
    try {
      ErrorHandler.logWarning(
        'NotificationError',
        'Bildirim hatası - varsayılan davranış uygulanıyor',
      );
      if (router != null && router.canPop()) {
        router.go('/home');
      }
    } catch (e, stack) {
      ErrorHandler.logError('NotificationError.fallback', e, stack);
    }
  }
}
