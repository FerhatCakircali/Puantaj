import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../models/notification_payload.dart';
import '../notification_constants.dart';
import 'notification_permission_mixin.dart';

/// Bildirim zamanlama işlemlerini yöneten mixin
/// Bu mixin bildirim zamanlama, iptal etme ve timezone yönetimi işlemlerini sağlar.
/// NotificationPermissionMixin'e bağımlıdır ve izin kontrollerini kullanır.
/// Sorumluluklar:
/// - Yevmiye hatırlatıcısı zamanlama
/// - Çalışan hatırlatıcısı zamanlama
/// - Bildirim iptal etme
/// - Timezone yönetimi (Europe/Istanbul)
/// - Bildirim detaylarını oluşturma
/// Kullanım:
/// ```dart
/// class NotificationService
///     with NotificationPermissionMixin, NotificationSchedulingMixin {
///   // ...
/// }
/// ```
mixin NotificationSchedulingMixin on NotificationPermissionMixin {
  /// FlutterLocalNotificationsPlugin instance'ına erişim
  /// Bu getter'ı implement eden sınıf tarafından sağlanmalıdır.
  FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin;

  /// Yevmiye hatırlatıcısını zamanlar
  /// Kullanıcı için günlük yevmiye girişi hatırlatıcısı oluşturur.
  /// Bildirim her gün belirlenen saatte tekrarlanır.
  /// [userId] Kullanıcı ID'si
  /// [username] Kullanıcı adı
  /// [fullName] Kullanıcının tam adı (ad + soyad)
  /// [time] Hatırlatıcı saati (TimeOfDay formatında)
  /// Özellikler:
  /// - İzin kontrolü yapar
  /// - Timezone-aware zamanlama (Europe/Istanbul)
  /// - Geçmiş saat için yarına zamanlar
  /// - Günlük tekrarlama (matchDateTimeComponents.time)
  /// - exactAllowWhileIdle modu (cihaz uyku modundayken bile çalışır)
  /// Örnek:
  /// ```dart
  /// await scheduleAttendanceReminder(
  ///   userId: 1,
  ///   username: 'ahmet',
  ///   fullName: 'Ahmet Yılmaz',
  ///   time: TimeOfDay(hour: 17, minute: 0),
  /// );
  /// ```
  Future<void> scheduleAttendanceReminder({
    required int userId,
    required String username,
    required String fullName,
    required TimeOfDay time,
  }) async {
    try {
      // İzinleri kontrol et
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) {
        debugPrint('Yevmiye hatırlatıcısı zamanlanamadı: İzin verilmedi');
        return;
      }

      // Bildirim ID'sini hesapla
      final notificationId = 1000 + userId;

      // Önce mevcut bildirimi iptal et (çoklu bildirim önleme)
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      debugPrint(
        'Mevcut yevmiye hatırlatıcısı iptal edildi: ID=$notificationId',
      );

      // Zamanlama tarihini hesapla
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // Eğer saat geçmişse yarına zamanla
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        debugPrint('Belirtilen saat geçmiş, yarına zamanlandı: $scheduledDate');
      }

      // TZDateTime'a çevir (Europe/Istanbul timezone)
      final tzDate = tz.TZDateTime.from(
        scheduledDate,
        tz.getLocation('Europe/Istanbul'),
      );

      // Payload oluştur
      final payload = NotificationPayload(
        type: NotificationType.attendanceReminder,
        userId: userId,
        username: username,
        fullName: fullName,
      );

      // Bildirimi zamanla
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Yevmiye Hatırlatıcısı',
        'Bugünkü yevmiye kayıtlarını girmeyi unutmayın.',
        tzDate,
        _buildNotificationDetails(NotificationChannels.attendanceReminder),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload.toJson(),
      );

      debugPrint('Yevmiye hatırlatıcısı zamanlandı: $tzDate');
      debugPrint('Kullanıcı: $fullName (ID: $userId)');
      debugPrint('Bildirim ID: $notificationId (1000 + $userId)');
    } catch (e, stackTrace) {
      debugPrint('Yevmiye hatırlatıcısı zamanlanırken hata: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Çalışan hatırlatıcısını zamanlar
  /// Belirli bir çalışan için özel hatırlatıcı oluşturur.
  /// Tek seferlik bildirim, belirlenen tarih ve saatte gösterilir.
  /// [reminderId] Hatırlatıcı ID'si (benzersiz bildirim ID'si olarak kullanılır)
  /// [userId] Kullanıcı ID'si
  /// [username] Kullanıcı adı
  /// [fullName] Kullanıcının tam adı
  /// [workerName] Çalışan adı
  /// [message] Hatırlatıcı mesajı
  /// [reminderDate] Hatırlatıcı tarihi ve saati
  /// Özellikler:
  /// - İzin kontrolü yapar
  /// - Geçmiş tarih kontrolü (geçmiş tarihli bildirimler zamanlanmaz)
  /// - Timezone-aware zamanlama (Europe/Istanbul)
  /// - Tek seferlik bildirim (matchDateTimeComponents yok)
  /// - exactAllowWhileIdle modu
  /// Örnek:
  /// ```dart
  /// await scheduleEmployeeReminder(
  ///   reminderId: 123,
  ///   userId: 1,
  ///   username: 'ahmet',
  ///   fullName: 'Ahmet Yılmaz',
  ///   workerName: 'Mehmet Demir',
  ///   message: 'Doğum günü bugün',
  ///   reminderDate: DateTime(2026, 3, 15, 9, 0),
  /// );
  /// ```
  Future<void> scheduleEmployeeReminder({
    required int reminderId,
    required int userId,
    required String username,
    required String fullName,
    required String workerName,
    required String message,
    required DateTime reminderDate,
  }) async {
    try {
      // İzinleri kontrol et
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) {
        debugPrint('Çalışan hatırlatıcısı zamanlanamadı: İzin verilmedi');
        return;
      }

      // Geçmiş tarih kontrolü
      if (reminderDate.isBefore(DateTime.now())) {
        debugPrint('Geçmiş tarihli hatırlatıcı zamanlanmadı: $reminderDate');
        return;
      }

      // TZDateTime'a çevir (Europe/Istanbul timezone)
      final tzDate = tz.TZDateTime.from(
        reminderDate,
        tz.getLocation('Europe/Istanbul'),
      );

      // Payload oluştur
      final payload = NotificationPayload(
        type: NotificationType.employeeReminder,
        userId: userId,
        username: username,
        fullName: fullName,
        reminderId: reminderId,
      );

      // Bildirimi zamanla
      await flutterLocalNotificationsPlugin.zonedSchedule(
        reminderId, // Benzersiz ID
        'Çalışan Hatırlatıcısı - $workerName',
        message,
        tzDate,
        _buildNotificationDetails(NotificationChannels.employeeReminders),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload.toJson(),
      );

      debugPrint(
        'Çalışan hatırlatıcısı zamanlandı: ID=$reminderId, Tarih=$tzDate',
      );
      debugPrint('Çalışan: $workerName, Kullanıcı: $fullName (ID: $userId)');
    } catch (e, stackTrace) {
      debugPrint('Çalışan hatırlatıcısı zamanlanırken hata: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Belirli bir bildirimi iptal eder
  /// Zamanlanmış bir bildirimi ID'sine göre iptal eder.
  /// [id] İptal edilecek bildirim ID'si
  /// Örnek:
  /// ```dart
  /// // Yevmiye hatırlatıcısını iptal et
  /// await cancelNotification(NotificationIds.attendanceReminder);
  /// // Çalışan hatırlatıcısını iptal et
  /// await cancelNotification(reminderId);
  /// ```
  Future<void> cancelNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('Bildirim iptal edildi: ID=$id');
    } catch (e) {
      debugPrint('Bildirim iptal edilirken hata: ID=$id, Hata: $e');
    }
  }

  /// Tüm zamanlanmış bildirimleri iptal eder
  /// Sistemdeki tüm zamanlanmış bildirimleri temizler.
  /// Kullanıcı çıkış yaptığında veya bildirimleri sıfırlamak gerektiğinde kullanılır.
  /// Örnek:
  /// ```dart
  /// // Kullanıcı çıkış yaparken
  /// await cancelAllNotifications();
  /// ```
  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('Tüm bildirimler iptal edildi');
    } catch (e) {
      debugPrint('Tüm bildirimler iptal edilirken hata: $e');
    }
  }

  /// Bildirim detaylarını oluşturur
  /// Platform-specific bildirim ayarlarını içeren NotificationDetails oluşturur.
  /// [channelId] Android bildirim kanalı ID'si
  /// Returns: Platform-specific bildirim detayları
  /// Android özellikleri:
  /// - Yüksek önem seviyesi (Importance.max)
  /// - Yüksek öncelik (Priority.high)
  /// - Özel ikon (ic_launcher_foreground)
  /// iOS özellikleri:
  /// - Alert gösterimi
  /// - Badge gösterimi
  /// - Ses çalma
  NotificationDetails _buildNotificationDetails(String channelId) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId == NotificationChannels.attendanceReminder
            ? 'Yevmiye Hatırlatıcısı'
            : 'Çalışan Hatırlatıcıları',
        channelDescription: channelId == NotificationChannels.attendanceReminder
            ? 'Günlük yevmiye girişi hatırlatıcısı'
            : 'Çalışanlarla ilgili hatırlatıcılar',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_launcher_foreground',
        enableVibration: true,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
