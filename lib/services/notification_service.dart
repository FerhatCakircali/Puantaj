import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_settings.dart';
import 'auth_service.dart';
import 'notification/mixins/notification_channel_mixin.dart';
import 'notification/mixins/notification_permission_mixin.dart';
import 'notification/mixins/notification_scheduling_mixin.dart';
import 'notification/mixins/notification_routing_mixin.dart';
import 'notification/mixins/notification_payload_mixin.dart';
import 'notification/core/notification_initializer.dart';
import 'notification/core/notification_settings_handler.dart';
import 'notification/core/notification_display_helper.dart';

/// Ana bildirim servisi - tüm mixin'leri ve helper'ları birleştirir
/// Bu servis bildirim sisteminin merkezi orchestrator'ıdır.
/// Tüm bildirim işlemlerini koordine eder ve dış dünyaya tek bir arayüz sunar.
/// Özellikler:
/// - Singleton pattern (tek instance)
/// - Mixin-based mimari (modüler yapı)
/// - Timezone-aware zamanlama (Europe/Istanbul)
/// - Platform-agnostic (Android & iOS)
/// - Fail-safe hata yönetimi
/// AGENTS.md uyumlu modüler yapı:
/// - NotificationInitializer: Başlatma işlemleri
/// - NotificationSettingsHandler: Ayar yönetimi
/// - NotificationDisplayHelper: Bildirim gösterme
/// Kullanım:
/// ```dart
/// final notificationService = NotificationService();
/// await notificationService.init();
/// ```
class NotificationService
    with
        NotificationChannelMixin,
        NotificationPermissionMixin,
        NotificationSchedulingMixin,
        NotificationRoutingMixin,
        NotificationPayloadMixin {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  @override
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final AuthService authService = AuthService();

  late final NotificationInitializer _initializer;
  late final NotificationSettingsHandler _settingsHandler;
  late final NotificationDisplayHelper _displayHelper;

  NotificationService._internal() {
    _initializer = NotificationInitializer(
      plugin: flutterLocalNotificationsPlugin,
      channelMixin: this,
      permissionMixin: this,
      payloadMixin: this,
    );

    _settingsHandler = NotificationSettingsHandler(
      plugin: flutterLocalNotificationsPlugin,
      authService: authService,
      schedulingMixin: this,
    );

    _displayHelper = NotificationDisplayHelper(
      plugin: flutterLocalNotificationsPlugin,
    );
  }

  /// Servisi başlatır
  Future<void> init() async {
    await _initializer.initialize();
  }

  /// Timezone'u başlatır
  Future<void> initializeTimezone() async {
    await _initializer.initializeTimezone();
  }

  /// Uygulama açıldığında bildirimleri kontrol et ve yeniden zamanla
  Future<void> checkAndRescheduleNotifications() async {
    await _settingsHandler.checkAndRescheduleNotifications();
  }

  /// Mevcut kullanıcı ID'sini döndürür
  Future<int?> getCurrentUserId() async {
    return authService.getUserId();
  }

  /// Bugün için yevmiye kaydı var mı kontrol eder
  Future<bool> hasAttendanceEntryForToday() async {
    return await _settingsHandler.hasAttendanceEntryForToday();
  }

  /// Bildirim ayarlarını veritabanından al
  Future<NotificationSettings?> getNotificationSettings() async {
    return await _settingsHandler.getNotificationSettings();
  }

  /// Bildirim ayarlarını güncelle
  Future<bool> updateNotificationSettings(NotificationSettings settings) async {
    return await _settingsHandler.updateNotificationSettings(settings);
  }

  /// Belirli bir bildirimi iptal eder
  @override
  Future<void> cancelNotification(int? id) async {
    await _displayHelper.cancelNotification(id);
  }

  /// Çıkış yapıldığında tüm bildirimleri temizle
  Future<void> clearAllNotificationsOnLogout() async {
    await _settingsHandler.clearAllNotificationsOnLogout();
  }

  /// Bekleyen bildirim bilgisini al (eski sistem uyumluluğu için)
  Future<dynamic> getPendingNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final type = prefs.getString('pending_notification_type');
      if (type == null) return null;

      final reminderId = prefs.getInt('pending_notification_reminder_id');
      return {'type': type, 'reminderId': reminderId};
    } catch (e) {
      debugPrint('getPendingNotification hatası: $e');
      return null;
    }
  }

  /// Bekleyen bildirim bilgisini temizle (eski sistem uyumluluğu için)
  Future<void> clearPendingNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_notification_type');
      await prefs.remove('pending_notification_reminder_id');
      debugPrint('Bekleyen bildirim temizlendi');
    } catch (e) {
      debugPrint('clearPendingNotification hatası: $e');
    }
  }

  /// Zamanlanmış bildirimleri listeler (eski sistem uyumluluğu için)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } catch (e) {
      debugPrint('getPendingNotifications hatası: $e');
      return [];
    }
  }

  /// Timezone dönüşüm helper'ı
  dynamic toTZDateTime(DateTime dateTime) {
    return _displayHelper.toTZDateTime(dateTime);
  }

  /// Şu anki zamanı TZDateTime olarak döndürür
  dynamic nowTZ() {
    return _displayHelper.nowTZ();
  }

  /// Belirli bir saat ve dakika için bugünün TZDateTime'ını oluşturur
  dynamic todayAt(int hour, int minute) {
    return _displayHelper.todayAt(hour, minute);
  }

  /// Anlık bildirim gösterir
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _displayHelper.showInstantNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Belirli bir zamanda bildirim göster
  Future<void> scheduleNotificationAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    await _displayHelper.scheduleNotificationAt(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      payload: payload,
    );
  }
}
