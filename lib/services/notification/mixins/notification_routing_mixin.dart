import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/notification_payload.dart';

/// Bildirim yönlendirme işlemlerini yöneten mixin
/// Bu mixin bildirime tıklandığında kullanıcıyı doğru sayfaya yönlendirme
/// işlemlerini sağlar. Uygulama kapalıyken tıklanan bildirimler için
/// routing bilgisini saklar ve uygulama açıldığında yönlendirmeyi gerçekleştirir.
/// Sorumluluklar:
/// - Bekleyen yönlendirmeleri kontrol etme
/// - Yevmiye hatırlatıcısı için yönlendirme
/// - Çalışan hatırlatıcısı için yönlendirme
/// - Yönlendirme bilgisini temizleme
/// - SharedPreferences entegrasyonu
/// Kullanım:
/// ```dart
/// class NotificationService with NotificationRoutingMixin {
///   // ...
/// }
/// ```
mixin NotificationRoutingMixin {
  /// Bekleyen bildirim yönlendirmesini kontrol eder ve işler
  /// Uygulama açıldığında çağrılmalıdır. SharedPreferences'ta bekleyen
  /// bir yönlendirme varsa, kullanıcıyı ilgili sayfaya yönlendirir.
  /// [context] BuildContext - Yönlendirme için gerekli
  /// Örnek:
  /// ```dart
  /// // main.dart veya ana sayfa initState'inde
  /// await notificationService.checkAndHandlePendingNotification(context);
  /// ```
  Future<void> checkAndHandlePendingNotification(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Bekleyen yönlendirme var mı kontrol et
      final hasPending = prefs.getBool('has_pending_notification') ?? false;
      if (!hasPending) {
        debugPrint('Bekleyen bildirim yönlendirmesi yok');
        return;
      }

      // Önce basit payload tipini kontrol et
      final simpleType = prefs.getString('notification_simple_type');
      if (simpleType != null) {
        debugPrint('Basit payload yönlendirmesi işleniyor: $simpleType');

        switch (simpleType) {
          case 'attendance_requests':
            await _handleAttendanceRequestsRoute(context);
            break;
          case 'user_notifications':
            await _handleUserNotificationsRoute(context);
            break;
          default:
            debugPrint('Bilinmeyen basit payload tipi: $simpleType');
        }

        await clearRoutingInfo();
        return;
      }

      // Çalışan bildirim tipini kontrol et (attendance_approved, attendance_rejected)
      final workerNotificationType = prefs.getString(
        'worker_notification_type',
      );
      if (workerNotificationType != null) {
        debugPrint(
          '🔔 Çalışan bildirim yönlendirmesi işleniyor: $workerNotificationType',
        );

        switch (workerNotificationType) {
          case 'attendance_approved':
          case 'attendance_rejected':
          case 'attendance_reminder':
            // Çalışan paneli - Hatırlatıcılar sayfasına yönlendir
            if (context.mounted) {
              debugPrint(
                '📍 Çalışan Hatırlatıcılar sayfasına yönlendiriliyor...',
              );
              context.go('/worker/home', extra: {'tab': 3});
              debugPrint(
                '✅ Çalışan Hatırlatıcılar sayfasına yönlendirme başarılı',
              );
            } else {
              debugPrint('Context mounted değil, yönlendirme iptal edildi');
            }
            break;
          case 'payment_received':
            // Çalışan paneli - Geçmiş sayfasına (Ödeme Geçmişi sekmesi) yönlendir
            if (context.mounted) {
              debugPrint(
                '📍 Çalışan Geçmiş sayfasına (Ödeme Geçmişi) yönlendiriliyor...',
              );

              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt(
                'worker_attendance_initial_tab',
                1,
              ); // 1 = Ödeme Geçmişi

              context.go('/worker/home', extra: {'tab': 1}); // Geçmiş sayfası
              debugPrint(
                '✅ Çalışan Geçmiş sayfasına (Ödeme Geçmişi sekmesi) yönlendirme başarılı',
              );
            } else {
              debugPrint('Context mounted değil, yönlendirme iptal edildi');
            }
            break;
          case 'payment_updated':
          case 'payment_deleted':
            // Çalışan paneli - Bildirimler sayfasına yönlendir
            if (context.mounted) {
              debugPrint('📍 Çalışan Bildirimler sayfasına yönlendiriliyor...');

              context.go(
                '/worker/home',
                extra: {'tab': 2},
              ); // Bildirimler sayfası
              debugPrint(
                '✅ Çalışan Bildirimler sayfasına yönlendirme başarılı',
              );
            } else {
              debugPrint('Context mounted değil, yönlendirme iptal edildi');
            }
            break;
          default:
            debugPrint(
              '⚠️ Bilinmeyen çalışan bildirim tipi: $workerNotificationType',
            );
        }

        await clearRoutingInfo();
        return;
      }

      // JSON payload tipini kontrol et
      final typeString = prefs.getString('notification_type');
      if (typeString == null) {
        debugPrint('Bildirim tipi bulunamadı');
        await clearRoutingInfo();
        return;
      }

      // Bildirim tipini parse et
      final type = NotificationType.fromJson(typeString);
      debugPrint('Bekleyen bildirim yönlendirmesi işleniyor: $type');

      // Bildirim tipine göre yönlendirme yap
      switch (type) {
        case NotificationType.attendanceReminder:
          await _handleAttendanceReminderRoute(context);
          break;
        case NotificationType.employeeReminder:
          await _handleEmployeeReminderRoute(context, prefs);
          break;
      }

      // Yönlendirme bilgisini temizle
      await clearRoutingInfo();
      debugPrint('Bildirim yönlendirmesi tamamlandı ve bilgiler temizlendi');
    } catch (e, stackTrace) {
      debugPrint('Bekleyen bildirim yönlendirmesi işlenirken hata: $e');
      debugPrint('Stack trace: $stackTrace');
      // Hata durumunda da bilgileri temizle
      await clearRoutingInfo();
    }
  }

  /// Yevmiye talepleri sayfasına yönlendirme yapar
  /// UserNotificationsScreen'e yönlendirir (HomeScreen'in 9. tab'ı - index 8).
  /// [context] BuildContext - Yönlendirme için gerekli
  Future<void> _handleAttendanceRequestsRoute(BuildContext context) async {
    try {
      debugPrint('Kullanıcı bildirimleri sayfasına yönlendiriliyor...');

      // GoRouter ile home sayfasına yönlendir (9. tab - Bildirimler, index 8)
      if (context.mounted) {
        context.go('/home', extra: {'tab': 8});
        debugPrint('Kullanıcı bildirimleri sayfasına yönlendirme başarılı');
      } else {
        debugPrint('Context artık geçerli değil, yönlendirme iptal edildi');
      }
    } catch (e, stackTrace) {
      debugPrint('Kullanıcı bildirimleri sayfasına yönlendirme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Kullanıcı bildirimleri sayfasına yönlendirme yapar
  /// UserNotificationsScreen'e yönlendirir (HomeScreen'in 9. tab'ı - index 8).
  /// [context] BuildContext - Yönlendirme için gerekli
  Future<void> _handleUserNotificationsRoute(BuildContext context) async {
    try {
      debugPrint('Kullanıcı bildirimleri sayfasına yönlendiriliyor...');

      // GoRouter ile home sayfasına yönlendir (9. tab - Bildirimler, index 8)
      if (context.mounted) {
        context.go('/home', extra: {'tab': 8});
        debugPrint('Kullanıcı bildirimleri sayfasına yönlendirme başarılı');
      } else {
        debugPrint('Context artık geçerli değil, yönlendirme iptal edildi');
      }
    } catch (e, stackTrace) {
      debugPrint('Kullanıcı bildirimleri sayfasına yönlendirme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Yevmiye hatırlatıcısı için yönlendirme yapar
  /// HomeScreen veya WorkerHomeScreen'e yönlendirir.
  /// worker_notification_type'a göre çalışan mı kullanıcı mı olduğunu belirler.
  /// [context] BuildContext - Yönlendirme için gerekli
  Future<void> _handleAttendanceReminderRoute(BuildContext context) async {
    try {
      debugPrint('Yevmiye sayfasına yönlendiriliyor...');

      // Çalışan mı kullanıcı mı kontrol et
      final prefs = await SharedPreferences.getInstance();

      // Çalışan oturumu var mı kontrol edelim
      final workerNotificationType = prefs.getString(
        'worker_notification_type',
      );
      final isWorker = workerNotificationType != null;

      if (!context.mounted) {
        debugPrint('Context artık geçerli değil, yönlendirme iptal edildi');
        return;
      }

      if (isWorker) {
        // Çalışan paneli - Hatırlatıcılar sayfasına yönlendir
        debugPrint('Çalışan Hatırlatıcılar sayfasına yönlendiriliyor...');
        context.go('/worker/home', extra: {'tab': 3});
        debugPrint('Çalışan Hatırlatıcılar sayfasına yönlendirme başarılı');
      } else {
        // Kullanıcı paneli - Yevmiye sayfasına yönlendir
        debugPrint('Kullanıcı Yevmiye sayfasına yönlendiriliyor...');
        context.go('/home', extra: {'tab': 1});
        debugPrint('Kullanıcı Yevmiye sayfasına yönlendirme başarılı');
      }
    } catch (e, stackTrace) {
      debugPrint('Yevmiye sayfasına yönlendirme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Çalışan hatırlatıcısı için yönlendirme yapar
  /// Kullanıcıyı ilgili hatırlatıcı detay sayfasına yönlendirir.
  /// [context] BuildContext - Yönlendirme için gerekli
  /// [prefs] SharedPreferences - Hatırlatıcı ID'sini almak için
  Future<void> _handleEmployeeReminderRoute(
    BuildContext context,
    SharedPreferences prefs,
  ) async {
    try {
      // Hatırlatıcı ID'sini al
      final reminderId = prefs.getInt('notification_reminder_id');
      if (reminderId == null) {
        debugPrint('Hatırlatıcı ID bulunamadı, yönlendirme yapılamıyor');
        return;
      }

      debugPrint(
        'Çalışan hatırlatıcısı detay sayfasına yönlendiriliyor: ID=$reminderId',
      );

      // GoRouter ile hatırlatıcı detay sayfasına yönlendir
      if (context.mounted) {
        context.go(
          '/employee_reminder_detail',
          extra: {'reminder_id': reminderId},
        );
        debugPrint(
          'Çalışan hatırlatıcısı detay sayfasına yönlendirme başarılı',
        );
      } else {
        debugPrint('Context artık geçerli değil, yönlendirme iptal edildi');
      }
    } catch (e, stackTrace) {
      debugPrint('Çalışan hatırlatıcısı yönlendirme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Yönlendirme bilgisini temizler
  /// SharedPreferences'ta saklanan tüm yönlendirme bilgilerini siler.
  /// Yönlendirme tamamlandıktan sonra veya hata durumunda çağrılmalıdır.
  /// Temizlenen bilgiler:
  /// - notification_type: Bildirim tipi
  /// - notification_simple_type: Basit payload tipi
  /// - notification_user_id: Kullanıcı ID'si
  /// - notification_reminder_id: Hatırlatıcı ID'si
  /// - notification_request_id: Talep ID'si
  /// - worker_notification_type: Çalışan bildirim tipi
  /// - worker_notification_id: Çalışan bildirim ID'si
  /// - has_pending_notification: Bekleyen yönlendirme bayrağı
  /// Örnek:
  /// ```dart
  /// await clearRoutingInfo();
  /// ```
  Future<void> clearRoutingInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Tüm yönlendirme bilgilerini temizle
      await prefs.remove('notification_type');
      await prefs.remove('notification_simple_type');
      await prefs.remove('notification_user_id');
      await prefs.remove('notification_reminder_id');
      await prefs.remove('notification_request_id');
      await prefs.remove('worker_notification_type');
      await prefs.remove('worker_notification_id');
      await prefs.setBool('has_pending_notification', false);

      debugPrint('Yönlendirme bilgisi temizlendi');
    } catch (e, stackTrace) {
      debugPrint('Yönlendirme bilgisi temizlenirken hata: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
}
