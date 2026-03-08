import 'package:flutter/foundation.dart';
import 'package:puantaj/data/services/supabase_service.dart';
import 'package:puantaj/data/services/local_storage_service.dart';
import 'package:puantaj/services/notification_service.dart';
import 'package:puantaj/services/fcm_service.dart';
import 'package:puantaj/services/cache_manager_service.dart';
import 'package:puantaj/core/di/service_locator.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Servis başlatma ve yapılandırma
/// Supabase, bildirimler ve FCM dahil tüm servis kurulumunu yönetir
class ServiceInitializer {
  /// Tüm uygulama servislerini başlat
  /// runApp() çağrılmadan önce çağrılmalıdır
  static Future<void> initialize() async {
    debugPrint('🔧 ServiceInitializer: Servis başlatma işlemi başlıyor');

    // Timezone başlatma (Türkiye saati - UTC+3)
    debugPrint('🔧 ServiceInitializer: Timezone başlatılıyor');
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    debugPrint('ServiceInitializer: Timezone ayarlandı (Europe/Istanbul)');

    // LocalStorage başlatma
    debugPrint('🔧 ServiceInitializer: LocalStorage başlatılıyor');
    await LocalStorageService.instance.initialize();
    debugPrint('ServiceInitializer: LocalStorage başlatıldı');

    // Supabase başlatma
    debugPrint('🔧 ServiceInitializer: Supabase başlatılıyor');
    await SupabaseService.instance.initialize(
      url: 'https://uvdcefauzxordqgvvweq.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2ZGNlZmF1enhvcmRxZ3Z2d2VxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4MjE5NzEsImV4cCI6MjA4NjM5Nzk3MX0.WWyRB9PfOTgWq55oc1sXDDRomL0D5C6ydILGxTDrqWU',
    );
    debugPrint('ServiceInitializer: Supabase başlatıldı');

    // Bildirim servisini başlat
    debugPrint('🔧 ServiceInitializer: Bildirim servisi başlatılıyor');
    final notificationService = NotificationService();
    await notificationService.init();
    debugPrint('ServiceInitializer: Bildirim servisi başlatıldı');

    // Uygulama açılışında bildirimleri kontrol et ve yeniden zamanla
    debugPrint('🔧 ServiceInitializer: Bildirimler kontrol ediliyor');
    await notificationService.checkAndRescheduleNotifications();
    debugPrint('ServiceInitializer: Bildirimler kontrol edildi');

    // FCM servisini başlat
    debugPrint('🔧 ServiceInitializer: FCM servisi başlatılıyor');
    await FCMService.instance.initialize();
    debugPrint('ServiceInitializer: FCM servisi başlatıldı');

    // Cache manager'ı başlat ve expired cache'leri temizle
    debugPrint('🔧 ServiceInitializer: Cache manager başlatılıyor');
    await getIt<CacheManagerService>().initializeCache();
    debugPrint('ServiceInitializer: Cache manager başlatıldı');

    debugPrint('ServiceInitializer: Tüm servisler başarıyla başlatıldı');
  }
}
