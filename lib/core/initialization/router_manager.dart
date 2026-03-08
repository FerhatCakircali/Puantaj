import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_routes.dart';
import '../error_handler.dart';

/// Router oluşturma ve yönetimini sağlayan sınıf
class RouterManager {
  /// Router'ı yapılandırır ve oluşturur
  static GoRouter createRouter({
    required bool isLoggedIn,
    required bool isCurrentUserAdmin,
    required Map<String, dynamic>? userData,
    GlobalKey<NavigatorState>? navigatorKey,
    String? forceInitialLocation,
  }) {
    try {
      debugPrint('Router yapılandırılıyor...');

      final isWorkerSession =
          userData != null && userData['id'] is String && !isLoggedIn;

      final location =
          forceInitialLocation ?? (isWorkerSession ? '/worker/home' : '/home');

      final router = AppRoutes.createRouter(
        isLoggedIn: isLoggedIn,
        isCurrentUserAdmin: isCurrentUserAdmin,
        navigatorKey: isLoggedIn ? navigatorKey : null,
        initialLocation: location,
      );

      debugPrint('Router yapılandırması tamamlandı');
      return router;
    } catch (e, stack) {
      ErrorHandler.logError('InitializeRouter', e, stack);
      rethrow;
    }
  }
}
