import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../mixins/notification_channel_mixin.dart';
import '../mixins/notification_permission_mixin.dart';
import '../mixins/notification_payload_mixin.dart';
import '../notification_helpers.dart';

/// Bildirim servisi başlatma işlemlerini yönetir
class NotificationInitializer {
  final FlutterLocalNotificationsPlugin plugin;
  final NotificationChannelMixin channelMixin;
  final NotificationPermissionMixin permissionMixin;
  final NotificationPayloadMixin payloadMixin;

  NotificationInitializer({
    required this.plugin,
    required this.channelMixin,
    required this.permissionMixin,
    required this.payloadMixin,
  });

  /// Servisi başlatır
  Future<void> initialize() async {
    try {
      debugPrint('NotificationService başlatılıyor...');

      await initializeTimezone();
      await _initializePlugin();

      if (Platform.isAndroid) {
        await channelMixin.createChannels();
      }

      final hasPermission = await permissionMixin.checkAndRequestPermissions();
      if (!hasPermission) {
        debugPrint('⚠️ Bildirim izinleri verilmedi');
      }

      await _handleColdStart();

      debugPrint('✅ NotificationService başarıyla başlatıldı');
    } catch (e, stackTrace) {
      debugPrint('❌ NotificationService başlatılırken hata: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Timezone'u başlatır
  Future<void> initializeTimezone() async {
    try {
      debugPrint('Timezone başlatılıyor...');

      tz.initializeTimeZones();

      try {
        final istanbul = tz.getLocation('Europe/Istanbul');
        tz.setLocalLocation(istanbul);
        debugPrint('✅ Timezone ayarlandı: ${tz.local.name}');
      } catch (e) {
        debugPrint('⚠️ Europe/Istanbul timezone ayarlanamadı: $e');
        debugPrint('UTC timezone\'una fallback yapılıyor...');
        tz.setLocalLocation(tz.UTC);
        debugPrint('✅ Fallback timezone ayarlandı: ${tz.local.name}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Timezone başlatılırken hata: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Plugin'i başlatır
  Future<void> _initializePlugin() async {
    try {
      debugPrint('Plugin başlatılıyor...');

      const androidSettings = AndroidInitializationSettings(
        'ic_launcher_foreground',
      );

      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      debugPrint('✅ Plugin başarıyla başlatıldı');
    } catch (e, stackTrace) {
      debugPrint('❌ Plugin başlatılırken hata: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Bildirime tıklandığında çağrılır (foreground)
  void _onNotificationTapped(NotificationResponse response) async {
    try {
      debugPrint('🔔 Bildirime tıklandı (foreground)');
      debugPrint('ID: ${response.id}');
      debugPrint('Payload: ${response.payload}');

      await payloadMixin.handleNotificationTap(response.payload);

      if (response.payload != null && response.payload!.isNotEmpty) {
        notificationClickStream.add(response.payload!);
        debugPrint('📡 Notification click event gönderildi');
      }

      debugPrint('✅ Bildirim tıklama işlendi (foreground)');
    } catch (e, stackTrace) {
      debugPrint('❌ Bildirim tıklama işlenirken hata: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Cold start durumunu handle eder
  Future<void> _handleColdStart() async {
    try {
      debugPrint('Cold start kontrolü yapılıyor...');

      final details = await plugin.getNotificationAppLaunchDetails();

      if (details == null) {
        debugPrint('Launch details bulunamadı');
        return;
      }

      if (details.didNotificationLaunchApp) {
        debugPrint('🚀 Uygulama bildirimden başlatıldı');

        final response = details.notificationResponse;
        if (response != null && response.payload != null) {
          debugPrint('Cold start payload: ${response.payload}');

          await payloadMixin.handleNotificationTap(response.payload);

          if (response.payload!.isNotEmpty) {
            notificationClickStream.add(response.payload!);
            debugPrint('📡 Cold start notification click event gönderildi');
          }

          debugPrint('✅ Cold start payload işlendi');
        }
      } else {
        debugPrint('Uygulama normal şekilde başlatıldı');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Cold start işlenirken hata: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
}
