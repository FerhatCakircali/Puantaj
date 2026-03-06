import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_globals.dart';
import '../../../services/notification_service.dart';

/// Yönetici (User) için bildirim dinleme servisi
/// Supabase Realtime kullanarak notifications tablosunu dinler.
/// Yeni bildirim geldiğinde local notification gösterir.
/// Singleton pattern ile tek instance garantisi.
class UserNotificationListenerService {
  UserNotificationListenerService._();

  static final UserNotificationListenerService _instance =
      UserNotificationListenerService._();

  /// Singleton instance
  static UserNotificationListenerService get instance => _instance;

  RealtimeChannel? _channel;
  int? _currentUserId;
  bool _isListening = false;

  /// Dinleme durumunu döndürür
  bool get isListening => _isListening;

  /// Yönetici için bildirim dinlemeyi başlatır
    /// [userId] - Dinlenecek yönetici ID'si
    /// Notifications tablosunda bu yöneticiye gelen yeni bildirimleri dinler.
  /// Yeni bildirim geldiğinde local notification gösterir.
  Future<void> startListening(int userId) async {
    try {
      // Zaten dinliyorsa ve aynı user ise, tekrar başlatma
      if (_isListening && _currentUserId == userId) {
        debugPrint('Bildirim dinleme zaten aktif (user: $userId)');
        return;
      }

      // Önceki dinlemeyi durdur
      await stopListening();

      debugPrint('🎧 Bildirim dinleme başlatılıyor (user: $userId)...');

      _currentUserId = userId;

      // Realtime channel oluştur
      _channel = supabase.channel('user_notifications_$userId');

      debugPrint('📡 Channel oluşturuldu: user_notifications_$userId');

      // Notifications tablosunu dinle
      _channel!
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'recipient_id',
              value: userId,
            ),
            callback: (payload) {
              debugPrint('REALTIME CALLBACK ÇAĞRILDI!');
              debugPrint('📬 Realtime: Yeni bildirim alındı');
              debugPrint('📬 Payload: ${payload.newRecord}');
              debugPrint('📬 Event type: ${payload.eventType}');
              debugPrint('📬 Table: ${payload.table}');
              _handleNewNotification(payload.newRecord);
            },
          )
          .subscribe((status, error) {
            debugPrint('📡 Subscription status: $status');
            if (error != null) {
              debugPrint('Subscription error: $error');
            }

            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint('REALTIME SUBSCRIBE BAŞARILI!');
              debugPrint('🎯 User ID: $userId için dinleme aktif');
              debugPrint('🎯 Channel: user_notifications_$userId');
            }
          });

      _isListening = true;
      debugPrint('Bildirim dinleme başlatıldı (user: $userId)');
    } catch (e, stackTrace) {
      debugPrint('Bildirim dinleme başlatılamadı: $e');
      debugPrint('Stack trace: $stackTrace');
      _isListening = false;
    }
  }

  /// Bildirim dinlemeyi durdurur
  Future<void> stopListening() async {
    try {
      if (_channel != null) {
        debugPrint('🛑 Bildirim dinleme durduruluyor...');
        await supabase.removeChannel(_channel!);
        _channel = null;
        _isListening = false;
        _currentUserId = null;
        debugPrint('Bildirim dinleme durduruldu');
      }
    } catch (e, stackTrace) {
      debugPrint('Bildirim dinleme durdurulurken hata: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Yeni bildirim geldiğinde çağrılır
    /// Local notification gösterir ve routing bilgisini kaydeder.
  /// ÇALIŞAN PANELİ İLE AYNI MANTIK: Payload ile routing bilgisi taşınır
  void _handleNewNotification(Map<String, dynamic> notification) async {
    try {
      debugPrint('_handleNewNotification ÇAĞRILDI!');
      debugPrint('Notification data: $notification');

      final notificationId = notification['id'] as int;
      final title = notification['title'] as String? ?? 'Yeni Bildirim';
      var message = notification['message'] as String? ?? '';

      // fullDay ve halfDay'i Türkçe'ye çevir
      message = message
          .replaceAll('(fullDay)', '(Tam Gün)')
          .replaceAll('(halfDay)', '(Yarım Gün)')
          .replaceAll('fullDay', 'Tam Gün')
          .replaceAll('halfDay', 'Yarım Gün');

      final notificationType =
          notification['notification_type'] as String? ?? '';
      final relatedId = notification['related_id'] as int?;

      debugPrint('📢 Local notification gösteriliyor...');
      debugPrint('ID: $notificationId');
      debugPrint('Başlık: $title');
      debugPrint('Mesaj: $message');
      debugPrint('Tip: $notificationType');
      debugPrint('Related ID: $relatedId');

            // ÇALIŞAN PANELİ İLE AYNI MANTIK: Basit string payload kullan
      // NotificationPayloadMixin bu payload'ı işleyecek ve routing bilgisini kaydedecek
      String payload = notificationType;

      // Related ID varsa payload'a ekle (çalışan panelindeki gibi)
      if (relatedId != null) {
        payload = '$notificationType:$relatedId';
        debugPrint('📦 Payload (related ID ile): $payload');
      } else {
        debugPrint('📦 Payload (sadece tip): $payload');
      }

      // Local notification göster
      // Payload bildirime tıklandığında NotificationPayloadMixin tarafından işlenecek
      NotificationService().showInstantNotification(
        id: notificationId,
        title: title,
        body: message,
        payload: payload,
      );

      debugPrint('Local notification gösterildi (Yöneticinin cihazında)');
      debugPrint(
        '  🎯 Bildirime tıklandığında NotificationPayloadMixin payload\'ı işleyecek',
      );
      debugPrint('  🎯 Routing bilgisi SharedPreferences\'a kaydedilecek');
      debugPrint('🎯 Kullanıcı ilgili sayfaya yönlendirilecek');
    } catch (e, stackTrace) {
      debugPrint('Bildirim işlenirken hata: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Servisi yeniden başlatır
    /// Bağlantı kopması durumunda kullanılabilir.
  Future<void> restart() async {
    if (_currentUserId != null) {
      await stopListening();
      await startListening(_currentUserId!);
    }
  }
}
