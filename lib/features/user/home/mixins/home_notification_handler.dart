import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../../../../features/user/services/user_notification_listener_service.dart';
import '../../../../features/worker/services/worker_notification_listener_service.dart';
import '../../../../services/notification_service.dart' as old_ns;

/// Ana ekran bildirim işlemleri handler'ı
class HomeNotificationHandler {
  final AuthService _authService = AuthService();

  /// Bekleyen bildirimi kontrol eder ve uygun yönlendirmeyi yapar
  Future<void> handlePendingNotification(BuildContext context) async {
    try {
      debugPrint('📭 HomeScreen: Bekleyen bildirim kontrol ediliyor...');

      if (!context.mounted) return;

      final notificationService = old_ns.NotificationService();
      await notificationService.checkAndHandlePendingNotification(context);

      debugPrint('HomeScreen: Bildirim kontrolü tamamlandı');
    } catch (e, stackTrace) {
      debugPrint('HomeScreen: Bildirim yönlendirmesi hatası: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Bildirim dinleme servisini başlatır
  Future<void> startNotificationListener() async {
    try {
      // Önce çalışan bildirim dinleyicisini durdur
      try {
        debugPrint(
          '🧹 Kullanıcı bildirim dinleyicisi başlatılmadan önce çalışan dinleyicisi kontrol ediliyor...',
        );
        await WorkerNotificationListenerService.instance.stopListening();
        debugPrint('Çalışan bildirim dinleyicisi durduruldu');
      } catch (e) {
        debugPrint(
          '⚠️ Çalışan bildirim dinleyicisi durdurulurken hata (devam ediliyor): $e',
        );
      }

      final user = await _authService.currentUser;
      if (user != null) {
        final userId = user['id'] as int;
        debugPrint('🎧 Bildirim dinleme başlatılıyor (user: $userId)');
        await UserNotificationListenerService.instance.startListening(userId);
        debugPrint('Bildirim dinleme başlatıldı');
      }
    } catch (e) {
      debugPrint('Bildirim dinleme başlatılamadı: $e');
    }
  }

  /// Bildirim dinleme servisini durdurur
  Future<void> stopNotificationListener() async {
    try {
      debugPrint('🛑 Bildirim dinleme durduruluyor');
      await UserNotificationListenerService.instance.stopListening();
      debugPrint('Bildirim dinleme durduruldu');
    } catch (e) {
      debugPrint('Bildirim dinleme durdurulurken hata: $e');
    }
  }

  // FCM ile anında bildirim gönderildiği için zamanlanmış kontrol artık gerekli değil
}
