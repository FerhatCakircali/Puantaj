import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_globals.dart';
import '../../../services/notification_service.dart';

/// Çalışan için bildirim dinleme servisi
/// Supabase Realtime kullanarak notifications tablosunu dinler.
/// Yeni bildirim geldiğinde local notification gösterir.
/// Singleton pattern ile tek instance garantisi.
class WorkerNotificationListenerService {
  WorkerNotificationListenerService._();

  static final WorkerNotificationListenerService _instance =
      WorkerNotificationListenerService._();

  /// Singleton instance
  static WorkerNotificationListenerService get instance => _instance;

  RealtimeChannel? _channel;
  int? _currentWorkerId;
  bool _isListening = false;

  /// Dinleme durumunu döndürür
  bool get isListening => _isListening;

  /// Çalışan için bildirim dinlemeyi başlatır
    /// [workerId] - Dinlenecek çalışan ID'si
    /// Notifications tablosunda bu çalışana gelen yeni bildirimleri dinler.
  /// Yeni bildirim geldiğinde local notification gösterir.
  Future<void> startListening(int workerId) async {
    try {
      // Zaten dinliyorsa ve aynı worker ise, tekrar başlatma
      if (_isListening && _currentWorkerId == workerId) {
        debugPrint('Bildirim dinleme zaten aktif (worker: $workerId)');
        return;
      }

      // Önceki dinlemeyi durdur
      await stopListening();

      debugPrint('🎧 Bildirim dinleme başlatılıyor (worker: $workerId)...');

      _currentWorkerId = workerId;

      // Realtime channel oluştur (kullanıcı servisi gibi basit)
      _channel = supabase.channel('worker_notifications_$workerId');

      debugPrint('📡 Channel oluşturuldu: worker_notifications_$workerId');

      // Notifications tablosunu dinle
      _channel!
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'recipient_id',
              value: workerId,
            ),
            callback: (payload) {
              debugPrint('📬 Yeni bildirim alındı: ${payload.newRecord}');
              _handleNewNotification(payload.newRecord);
            },
          )
          .subscribe((status, error) {
            debugPrint('📡 Subscription status: $status');
            if (error != null) {
              debugPrint('Subscription error: $error');
            }
          });

      _isListening = true;
      debugPrint('Bildirim dinleme başlatıldı (worker: $workerId)');
    } catch (e, stackTrace) {
      debugPrint('Bildirim dinleme başlatılamadı: $e');
      debugPrint('Stack trace: $stackTrace');
      _isListening = false;
    }
  }

  /// Bildirim dinlemeyi durdurur (kullanıcı servisi ile aynı)
  Future<void> stopListening() async {
    try {
      if (_channel != null) {
        debugPrint('🛑 Bildirim dinleme durduruluyor...');
        await supabase.removeChannel(_channel!);
        _channel = null;
        _isListening = false;
        _currentWorkerId = null;
        debugPrint('Bildirim dinleme durduruldu');
      }
    } catch (e, stackTrace) {
      debugPrint('Bildirim dinleme durdurulurken hata: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Yeni bildirim geldiğinde çağrılır
    /// Local notification gösterir ve routing bilgisini kaydeder.
  /// KULLANICI PANELİ İLE AYNI MANTIK: Payload ile routing bilgisi taşınır
  void _handleNewNotification(Map<String, dynamic> notification) async {
    try {
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
      final relatedId = notification['related_id'];

      debugPrint('📢 Local notification gösteriliyor...');
      debugPrint('ID: $notificationId');
      debugPrint('Başlık: $title');
      debugPrint('Mesaj: $message');
      debugPrint('Tip: $notificationType');
      debugPrint('Related ID: $relatedId');

            // KULLANICI PANELİ İLE AYNI MANTIK: Basit string payload kullan
      // NotificationPayloadMixin bu payload'ı işleyecek ve routing bilgisini kaydedecek
      String payload = notificationType;

      // Related ID varsa payload'a ekle (kullanıcı panelindeki gibi)
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

      debugPrint('Local notification gösterildi');
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
    if (_currentWorkerId != null) {
      await stopListening();
      await startListening(_currentWorkerId!);
    }
  }
}
