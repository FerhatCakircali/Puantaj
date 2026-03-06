import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/notification_payload.dart';

/// Bildirim payload yönetimi için mixin
/// Bu mixin bildirim payload'larını ayrıştırma, doğrulama ve
/// routing bilgilerini kaydetme işlemlerini sağlar.
/// Sorumluluklar:
/// - Bildirime tıklandığında payload'ı ayrıştırma
/// - Payload doğrulama
/// - Routing bilgisini SharedPreferences'a kaydetme
/// - Hata yönetimi
/// Kullanım:
/// ```dart
/// class NotificationService with NotificationPayloadMixin {
///   // ...
/// }
/// ```
mixin NotificationPayloadMixin {
  /// Bildirime tıklandığında çağrılır
    /// Payload string'ini ayrıştırır, doğrular ve routing bilgisini kaydeder.
  /// Uygulama kapalıyken tıklanan bildirimler için payload saklanır.
    /// [payloadString] Bildirimden gelen JSON formatında payload string'i
  ///                 veya basit string (örn: 'attendance_requests')
    /// İşlem adımları:
  /// 1. Payload null kontrolü
  /// 2. Basit string mi JSON mu kontrol et
  /// 3. JSON ise ayrıştır, basit string ise direkt işle
  /// 4. Routing bilgisini kaydetme
  /// 5. Hata durumunda loglama
    /// Örnek:
  /// ```dart
  /// await handleNotificationTap(payloadString);
  /// ```
  Future<void> handleNotificationTap(String? payloadString) async {
    try {
      debugPrint('🎯🎯🎯 handleNotificationTap ÇAĞRILDI!');
      debugPrint('📦 Payload: $payloadString');

      // Null kontrolü
      if (payloadString == null || payloadString.isEmpty) {
        debugPrint('Payload boş veya null');
        return;
      }

      // Basit string payload kontrolü (örn: 'attendance_requests')
      if (!payloadString.startsWith('{')) {
        debugPrint('Basit string payload tespit edildi');
        // JSON değil, basit string payload
        await _handleSimplePayload(payloadString);
        return;
      }

      debugPrint('JSON payload tespit edildi');
      // JSON payload - mevcut işlem
      final payload = NotificationPayload.fromJson(payloadString);
      if (payload == null) {
        debugPrint('Geçersiz payload: Ayrıştırma başarısız');
        return;
      }

      // Payload doğrulama
      if (!_validatePayload(payload)) {
        debugPrint('Geçersiz payload: Doğrulama başarısız');
        return;
      }

      // Routing bilgisini kaydet
      await saveRoutingInfo(payload);

      debugPrint('Bildirim payload işlendi: ${payload.type}');
      debugPrint('👤 Kullanıcı: ${payload.fullName} (ID: ${payload.userId})');
      if (payload.reminderId != null) {
        debugPrint('Hatırlatıcı ID: ${payload.reminderId}');
      }
    } catch (e, stackTrace) {
      debugPrint('Bildirim payload işlenirken hata: $e');
      debugPrint('📚 Stack trace: $stackTrace');
    }
  }

  /// Basit string payload'ları işler
    /// JSON olmayan basit string payload'lar için kullanılır.
  /// Örnek: 'attendance_requests', 'attendance_request:72'
    /// [payload] Basit string payload
  Future<void> _handleSimplePayload(String payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      debugPrint('Basit payload işleniyor: $payload');

      // attendance_request:ID formatını kontrol et
      if (payload.startsWith('attendance_request:')) {
        // ID'yi çıkar
        final parts = payload.split(':');
        if (parts.length == 2) {
          final requestId = int.tryParse(parts[1]);
          if (requestId != null) {
            await prefs.setString(
              'notification_simple_type',
              'user_notifications',
            );
            await prefs.setInt('notification_request_id', requestId);
            await prefs.setBool('has_pending_notification', true);
            debugPrint(
              '✅ Yevmiye talebi payload işlendi (ID: $requestId) - bildirimler sayfasına yönlendirilecek',
            );
            return;
          }
        }
      }

      // Çalışan bildirim tiplerini kontrol et (attendance_approved:ID formatı)
      // KULLANICI PANELİ İLE AYNI MANTIK: related_id ile payload formatı
      if (payload.startsWith('attendance_approved:') ||
          payload.startsWith('attendance_rejected:') ||
          payload.startsWith('attendance_reminder:') ||
          payload.startsWith('payment_received:') ||
          payload.startsWith('payment_updated:') ||
          payload.startsWith('payment_deleted:')) {
        // ID'yi çıkar
        final parts = payload.split(':');
        if (parts.length == 2) {
          final notificationType = parts[0];
          final relatedId = int.tryParse(parts[1]);

          debugPrint('Çalışan bildirimi tespit edildi: $notificationType');
          await prefs.setString('worker_notification_type', notificationType);
          await prefs.setBool('has_pending_notification', true);

          if (relatedId != null) {
            await prefs.setInt('worker_notification_id', relatedId);
            debugPrint(
              '✅ Çalışan bildirimi payload işlendi (ID: $relatedId) - yönlendirilecek',
            );
          } else {
            debugPrint('Çalışan bildirimi payload işlendi - yönlendirilecek');
          }
          return;
        }
      }

      // Payload tipine göre routing bilgisini kaydet
      switch (payload) {
        case 'attendance_requests':
        case 'attendance_request': // Realtime subscription'dan gelen
          await prefs.setString(
            'notification_simple_type',
            'user_notifications', // Bildirimler sayfasına yönlendir
          );
          await prefs.setBool('has_pending_notification', true);
          debugPrint(
            '✅ Yevmiye talepleri payload işlendi - bildirimler sayfasına yönlendirilecek',
          );
          break;
        case 'attendance_approved':
        case 'attendance_rejected':
        case 'attendance_reminder':
        case 'payment_received':
        case 'payment_updated':
        case 'payment_deleted':
                    // ID olmadan gelen bildirimler için (eski format uyumluluğu)
          debugPrint('Çalışan bildirimi tespit edildi: $payload');
          await prefs.setString('worker_notification_type', payload);
          await prefs.setBool('has_pending_notification', true);
          debugPrint('Çalışan bildirimi payload işlendi - yönlendirilecek');
          break;
        default:
          debugPrint('Bilinmeyen basit payload: $payload');
      }
    } catch (e, stackTrace) {
      debugPrint('Basit payload işlenirken hata: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Routing bilgisini SharedPreferences'a kaydeder
    /// Uygulama açıldığında bu bilgiler kullanılarak
  /// kullanıcı doğru sayfaya yönlendirilir.
    /// [payload] Kaydedilecek payload bilgisi
    /// Kaydedilen bilgiler:
  /// - notification_type: Bildirim tipi (attendanceReminder/employeeReminder)
  /// - notification_user_id: Kullanıcı ID'si
  /// - notification_reminder_id: Hatırlatıcı ID'si (sadece employeeReminder için)
  /// - has_pending_notification: Bekleyen yönlendirme var mı?
  /// - worker_notification_type: Çalışan için bildirim tipi (username worker_ ile başlıyorsa)
    /// Örnek:
  /// ```dart
  /// await saveRoutingInfo(payload);
  /// ```
  Future<void> saveRoutingInfo(NotificationPayload payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Bildirim tipini kaydet
      await prefs.setString('notification_type', payload.type.toJson());

      // Kullanıcı ID'sini kaydet
      await prefs.setInt('notification_user_id', payload.userId);

      // Çalışan mı kontrol et (username worker_ ile başlıyorsa)
      final isWorker = payload.username.startsWith('worker_');
      if (isWorker && payload.type == NotificationType.attendanceReminder) {
        // Çalışan için özel routing bilgisi kaydet
        await prefs.setString(
          'worker_notification_type',
          'attendance_reminder',
        );
        await prefs.setInt('worker_notification_id', payload.userId);
        debugPrint('Çalışan routing bilgisi kaydedildi');
      }

      // Çalışan hatırlatıcısı için reminder ID'yi kaydet
      if (payload.reminderId != null) {
        await prefs.setInt('notification_reminder_id', payload.reminderId!);
      } else {
        // Önceki reminder ID'yi temizle
        await prefs.remove('notification_reminder_id');
      }

      // Bekleyen yönlendirme bayrağını set et
      await prefs.setBool('has_pending_notification', true);

      debugPrint('Routing bilgisi kaydedildi: ${payload.type}');
    } catch (e, stackTrace) {
      debugPrint('Routing bilgisi kaydedilirken hata: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Payload'ı doğrular
    /// Payload'daki zorunlu alanların geçerli olup olmadığını kontrol eder.
    /// [payload] Doğrulanacak payload
    /// Returns: Payload geçerliyse true, değilse false
    /// Doğrulama kuralları:
  /// - userId pozitif olmalı
  /// - username boş olmamalı
  /// - fullName boş olmamalı
  /// - employeeReminder tipinde reminderId olmalı ve pozitif olmalı
  bool _validatePayload(NotificationPayload payload) {
    // User ID kontrolü
    if (payload.userId <= 0) {
      debugPrint('Geçersiz userId: ${payload.userId}');
      return false;
    }

    // Username kontrolü
    if (payload.username.trim().isEmpty) {
      debugPrint('Geçersiz username: boş');
      return false;
    }

    // Full name kontrolü
    if (payload.fullName.trim().isEmpty) {
      debugPrint('Geçersiz fullName: boş');
      return false;
    }

    // Çalışan hatırlatıcısı için reminder ID kontrolü
    if (payload.type == NotificationType.employeeReminder) {
      if (payload.reminderId == null || payload.reminderId! <= 0) {
        debugPrint('Geçersiz reminderId: ${payload.reminderId}');
        return false;
      }
    }

    return true;
  }
}
