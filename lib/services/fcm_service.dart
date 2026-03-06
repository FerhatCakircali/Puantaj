import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../core/app_globals.dart';
import 'notification_service.dart';

/// Firebase Cloud Messaging Servisi
/// Push notification alır ve local notification gösterir.
/// Uygulama kapalıyken bile çalışır.
/// Singleton pattern ile tek instance garantisi.
class FCMService {
  FCMService._();

  static final FCMService _instance = FCMService._();

  /// Singleton instance
  static FCMService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  /// FCM token'ı döndürür
  String? get fcmToken => _fcmToken;

  /// FCM servisini başlatır
    /// İzin ister, token alır, listener'ları kurar.
  Future<void> initialize() async {
    try {
      debugPrint('FCM servisi başlatılıyor...');

      // İzin iste
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('FCM izni verildi');
      } else {
        debugPrint('FCM izni reddedildi');
        return;
      }

      // FCM token al
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Token yenilendiğinde
      _messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        debugPrint('🔄 FCM Token yenilendi: $newToken');

        // Token'ı Supabase'e kaydet (mevcut kullanıcı/çalışan için)
        // NOT: Bu otomatik çalışır, manuel kayıt gerekmez
        try {
          // Mevcut token'ı güncelle
          await supabase
              .from('fcm_tokens')
              .update({
                'token': newToken,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('token', _fcmToken!);

          debugPrint('✅ Yenilenmiş token Supabase\'e kaydedildi');
        } catch (e) {
          debugPrint('Token yenileme kaydedilemedi: $e');
        }
      });

      // Foreground mesajları dinle (uygulama açıkken)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Background mesajları dinle (uygulama kapalıyken)
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Bildirime tıklandığında (uygulama kapalıyken açıldı)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Uygulama kapalıyken gelen bildirime tıklanarak açıldıysa
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      debugPrint('FCM servisi başlatıldı');
    } catch (e, stackTrace) {
      debugPrint('FCM servisi başlatılamadı: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Foreground mesajını işler (uygulama açıkken)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📬 FCM Foreground mesaj alındı');
    debugPrint('Başlık: ${message.notification?.title}');
    debugPrint('Mesaj: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

        // Çünkü Realtime subscription zaten bildirim gösteriyor
    debugPrint(
      '  ℹ️ Uygulama açık - Local notification gösterilmiyor (Realtime aktif)',
    );

    // NOT: Eğer Realtime çalışmıyorsa, local notification göstermek için
    // aşağıdaki satırı uncomment et:
    // _showLocalNotification(message);
  }

  /// Mesaj açıldığında (bildirime tıklandı)
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM mesajına tıklandı!');
    debugPrint('📦 Data: ${message.data}');

    // Notification type'a göre yönlendirme
    final notificationType = message.data['notification_type'] as String?;
    final relatedId = message.data['related_id'];

    debugPrint('🏷 Type: $notificationType');
    debugPrint('🔗 Related ID: $relatedId');

    // NotificationService ile routing yap
    if (notificationType != null) {
      debugPrint('NotificationService.handleNotificationTap çağrılıyor...');

      // Related ID varsa payload'a ekle
      String payload = notificationType;
      if (relatedId != null) {
        payload = '$notificationType:$relatedId';
        debugPrint('📦 Payload oluşturuldu: $payload');
      }

      NotificationService().handleNotificationTap(payload);
      debugPrint('handleNotificationTap çağrıldı');
    } else {
      debugPrint('notification_type NULL! Yönlendirme yapılamıyor!');
    }
  }

  /// FCM token'ı Supabase'e kaydet (User için)
    /// [userId] - Kullanıcı ID'si
  /// [deviceInfo] - Cihaz bilgileri (opsiyonel)
  Future<void> saveTokenForUser(
    int userId, {
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      if (_fcmToken == null) {
        debugPrint('FCM token yok, kaydedilemedi');
        return;
      }

      debugPrint('💾 FCM token Supabase\'e kaydediliyor (User: $userId)...');

      // Önce mevcut token'ı kontrol et
      final existing = await supabase
          .from('fcm_tokens')
          .select()
          .eq('token', _fcmToken!)
          .maybeSingle();

      if (existing != null) {
        // Token zaten var - güncelle
        await supabase
            .from('fcm_tokens')
            .update({
              'user_id': userId,
              'worker_id': null,
              'is_active': true,
              'last_used_at': DateTime.now().toIso8601String(),
              'device_info': deviceInfo ?? {},
            })
            .eq('token', _fcmToken!);

        debugPrint('Mevcut FCM token güncellendi');
      } else {
        // Yeni token - ekle
        await supabase.from('fcm_tokens').insert({
          'user_id': userId,
          'worker_id': null,
          'token': _fcmToken,
          'device_type': 'android', // TODO: Platform detection
          'device_info': deviceInfo ?? {},
          'is_active': true,
        });

        debugPrint('Yeni FCM token kaydedildi');
      }
    } catch (e, stackTrace) {
      debugPrint('FCM token kaydedilemedi: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// FCM token'ı Supabase'e kaydet (Worker için)
    /// [workerId] - Çalışan ID'si
  /// [deviceInfo] - Cihaz bilgileri (opsiyonel)
  Future<void> saveTokenForWorker(
    int workerId, {
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      if (_fcmToken == null) {
        debugPrint('FCM token yok, kaydedilemedi');
        return;
      }

      debugPrint(
        '💾 FCM token Supabase\'e kaydediliyor (Worker: $workerId)...',
      );

      // Önce mevcut token'ı kontrol et
      final existing = await supabase
          .from('fcm_tokens')
          .select()
          .eq('token', _fcmToken!)
          .maybeSingle();

      if (existing != null) {
        // Token zaten var - güncelle
        await supabase
            .from('fcm_tokens')
            .update({
              'user_id': null,
              'worker_id': workerId,
              'is_active': true,
              'last_used_at': DateTime.now().toIso8601String(),
              'device_info': deviceInfo ?? {},
            })
            .eq('token', _fcmToken!);

        debugPrint('Mevcut FCM token güncellendi');
      } else {
        // Yeni token - ekle
        await supabase.from('fcm_tokens').insert({
          'user_id': null,
          'worker_id': workerId,
          'token': _fcmToken,
          'device_type': 'android', // TODO: Platform detection
          'device_info': deviceInfo ?? {},
          'is_active': true,
        });

        debugPrint('Yeni FCM token kaydedildi');
      }
    } catch (e, stackTrace) {
      debugPrint('FCM token kaydedilemedi: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// FCM token'ı Supabase'den sil
    /// Logout veya cihaz değişikliğinde kullanılır.
  Future<void> deleteToken() async {
    try {
      if (_fcmToken == null) {
        debugPrint('FCM token yok, silinemedi');
        return;
      }

      debugPrint('🗑️ FCM token Supabase\'den siliniyor...');

      await supabase.from('fcm_tokens').delete().eq('token', _fcmToken!);

      debugPrint('FCM token silindi');
    } catch (e, stackTrace) {
      debugPrint('FCM token silinemedi: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// FCM token'ı deaktif et (silmeden)
    /// Geçici olarak bildirimleri durdurmak için kullanılır.
  Future<void> deactivateToken() async {
    try {
      if (_fcmToken == null) {
        debugPrint('FCM token yok, deaktif edilemedi');
        return;
      }

      debugPrint('⏸ FCM token deaktif ediliyor...');

      await supabase
          .from('fcm_tokens')
          .update({'is_active': false})
          .eq('token', _fcmToken!);

      debugPrint('FCM token deaktif edildi');
    } catch (e, stackTrace) {
      debugPrint('FCM token deaktif edilemedi: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
}

/// Background mesaj handler (top-level function olmalı)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 FCM Background mesaj alındı');
  debugPrint('Başlık: ${message.notification?.title}');
  debugPrint('Mesaj: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');

  // Firebase'i initialize et (background'da gerekli)
  // await Firebase.initializeApp();

  // Local notification zaten Firebase tarafından gösterilir
}
