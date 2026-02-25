import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../notification_constants.dart';

/// Android bildirim kanallarını yönetir
///
/// Bu mixin Android platformunda bildirim kanallarının oluşturulmasından sorumludur.
/// iOS'ta bildirim kanalları kullanılmadığı için platform kontrolü yapar.
///
/// Üç farklı kanal tanımlar:
/// - Yevmiye hatırlatıcısı kanalı
/// - Çalışan hatırlatıcıları kanalı
/// - Xiaomi cihazlar için özel yüksek önem kanalı
mixin NotificationChannelMixin {
  /// Tüm bildirim kanallarını oluşturur
  ///
  /// Android platformunda çalışır. iOS'ta hiçbir işlem yapmaz.
  /// Her kanal için önem seviyesi, ses, titreşim ve badge ayarları yapılandırılır.
  ///
  /// Xiaomi cihazlarda bildirimlerin düzgün gösterilmesi için
  /// özel bir yüksek önem kanalı da oluşturulur.
  Future<void> createChannels() async {
    // iOS'ta bildirim kanalları kullanılmaz
    if (!Platform.isAndroid) return;

    final plugin = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (plugin == null) {
      debugPrint('Android bildirim plugin\'i bulunamadı');
      return;
    }

    try {
      // Yevmiye hatırlatıcısı kanalını oluştur
      await plugin.createNotificationChannel(_attendanceChannel);
      debugPrint('Yevmiye hatırlatıcısı kanalı oluşturuldu');

      // Yevmiye talep bildirimleri kanalını oluştur
      await plugin.createNotificationChannel(_attendanceRequestsChannel);
      debugPrint('Yevmiye talep bildirimleri kanalı oluşturuldu');

      // Çalışan hatırlatıcıları kanalını oluştur
      await plugin.createNotificationChannel(_employeeChannel);
      debugPrint('Çalışan hatırlatıcıları kanalı oluşturuldu');

      // Xiaomi özel kanalını oluştur
      await plugin.createNotificationChannel(_xiaomiChannel);
      debugPrint('Xiaomi özel kanalı oluşturuldu');
    } catch (e) {
      debugPrint('Bildirim kanalları oluşturulurken hata: $e');
    }
  }

  /// Yevmiye hatırlatıcısı kanalı
  ///
  /// Günlük yevmiye girişi hatırlatıcıları için kullanılır.
  /// Maksimum önem seviyesi ile yapılandırılmıştır.
  AndroidNotificationChannel get _attendanceChannel =>
      const AndroidNotificationChannel(
        NotificationChannels.attendanceReminder,
        'Yevmiye Hatırlatıcısı',
        description: 'Günlük yevmiye girişi hatırlatıcısı',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );

  /// Yevmiye talep bildirimleri kanalı
  ///
  /// Çalışanlar tarafından gönderilen yevmiye talepleri için kullanılır.
  /// FCM ile anında bildirim gönderilir.
  /// Maksimum önem seviyesi ile yapılandırılmıştır.
  AndroidNotificationChannel get _attendanceRequestsChannel =>
      const AndroidNotificationChannel(
        NotificationChannels.attendanceRequests,
        'Yevmiye Talepleri',
        description: 'Çalışan yevmiye talep bildirimleri (FCM)',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );

  /// Çalışan hatırlatıcıları kanalı
  ///
  /// Çalışanlarla ilgili hatırlatıcılar için kullanılır.
  /// (Doğum günü, izin dönüşü, vb.)
  /// Maksimum önem seviyesi ile yapılandırılmıştır.
  AndroidNotificationChannel get _employeeChannel =>
      const AndroidNotificationChannel(
        NotificationChannels.employeeReminders,
        'Çalışan Hatırlatıcıları',
        description: 'Çalışanlarla ilgili hatırlatıcılar',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );

  /// Xiaomi cihazlar için özel yüksek önem kanalı
  ///
  /// Xiaomi cihazlarda bildirimlerin düzgün gösterilmesi için
  /// özel yapılandırılmış kanal.
  /// Maksimum önem seviyesi ve tüm bildirim özellikleri etkin.
  AndroidNotificationChannel get _xiaomiChannel =>
      const AndroidNotificationChannel(
        NotificationChannels.xiaomiHighImportance,
        'Önemli Bildirimler',
        description: 'Yüksek öncelikli sistem bildirimleri',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );
}
