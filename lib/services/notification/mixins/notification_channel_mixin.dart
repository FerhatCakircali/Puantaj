import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../notification_constants.dart';

/// Android bildirim kanallarını yönetir
///
/// Bu mixin Android platformunda bildirim kanallarının oluşturulmasından sorumludur.
/// iOS'ta bildirim kanalları kullanılmadığı için platform kontrolü yapar.
///
/// Tüm Android cihazlar (Samsung, Xiaomi, Oppo, Huawei, Realme, vb.) için
/// optimize edilmiş üç farklı kanal tanımlar:
/// - Yevmiye hatırlatıcısı kanalı
/// - Yevmiye talep bildirimleri kanalı
/// - Çalışan hatırlatıcıları kanalı
mixin NotificationChannelMixin {
  /// Tüm bildirim kanallarını oluşturur
  ///
  /// Android platformunda çalışır. iOS'ta hiçbir işlem yapmaz.
  /// Her kanal için önem seviyesi, ses, titreşim ve badge ayarları yapılandırılır.
  ///
  /// Maksimum önem seviyesi (Importance.max) kullanılarak tüm Android cihazlarda
  /// bildirimlerin düzgün gösterilmesi sağlanır.
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
      debugPrint('✅ Yevmiye hatırlatıcısı kanalı oluşturuldu');

      // Yevmiye talep bildirimleri kanalını oluştur
      await plugin.createNotificationChannel(_attendanceRequestsChannel);
      debugPrint('✅ Yevmiye talep bildirimleri kanalı oluşturuldu');

      // Çalışan hatırlatıcıları kanalını oluştur
      await plugin.createNotificationChannel(_employeeChannel);
      debugPrint('✅ Çalışan hatırlatıcıları kanalı oluşturuldu');

      debugPrint('✅ Tüm bildirim kanalları başarıyla oluşturuldu');
    } catch (e) {
      debugPrint('❌ Bildirim kanalları oluşturulurken hata: $e');
    }
  }

  /// Yevmiye hatırlatıcısı kanalı
  ///
  /// Günlük yevmiye girişi hatırlatıcıları için kullanılır.
  /// Maksimum önem seviyesi ile yapılandırılmıştır.
  /// Tüm Android cihazlarda (Samsung, Xiaomi, Oppo, Huawei, vb.) çalışır.
  AndroidNotificationChannel get _attendanceChannel =>
      const AndroidNotificationChannel(
        NotificationChannels.attendanceReminder,
        'Yevmiye Hatırlatıcısı',
        description: 'Günlük yevmiye girişi hatırlatıcısı',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
        enableLights: true,
      );

  /// Yevmiye talep bildirimleri kanalı
  ///
  /// Çalışanlar tarafından gönderilen yevmiye talepleri için kullanılır.
  /// FCM ile anında bildirim gönderilir.
  /// Maksimum önem seviyesi ile yapılandırılmıştır.
  /// Tüm Android cihazlarda (Samsung, Xiaomi, Oppo, Huawei, vb.) çalışır.
  AndroidNotificationChannel get _attendanceRequestsChannel =>
      const AndroidNotificationChannel(
        NotificationChannels.attendanceRequests,
        'Yevmiye Talepleri',
        description: 'Çalışan yevmiye talep bildirimleri',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
        enableLights: true,
      );

  /// Çalışan hatırlatıcıları kanalı
  ///
  /// Çalışanlarla ilgili hatırlatıcılar için kullanılır.
  /// (Doğum günü, izin dönüşü, vb.)
  /// Maksimum önem seviyesi ile yapılandırılmıştır.
  /// Tüm Android cihazlarda (Samsung, Xiaomi, Oppo, Huawei, vb.) çalışır.
  AndroidNotificationChannel get _employeeChannel =>
      const AndroidNotificationChannel(
        NotificationChannels.employeeReminders,
        'Çalışan Hatırlatıcıları',
        description: 'Çalışanlarla ilgili hatırlatıcılar',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
        enableLights: true,
      );
}
