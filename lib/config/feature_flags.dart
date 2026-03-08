/// FeatureFlags - Özellik bayrakları yapılandırma sınıfı.
/// Bu sınıf, uygulamadaki yeni özellikleri kontrollü şekilde açıp kapatmak
/// için kullanılır. Optimizasyon sürecinde eski ve yeni implementasyonlar
/// arasında geçiş yapmayı sağlar.
/// **Özellikler:**
/// - Riverpod state management kontrolü
/// - Cache mekanizması kontrolü
/// - Optimize edilmiş ListView kontrolü
/// - Tek bir yerden tüm özellikleri yönetme
/// **Kullanım:**
/// ```dart
/// // Riverpod kullanılıyor mu kontrol et
/// if (FeatureFlags.useRiverpod) {
///   // Yeni Riverpod implementasyonu
/// } else {
///   // Eski ValueNotifier implementasyonu
/// }
/// // Cache kullanılıyor mu kontrol et
/// if (FeatureFlags.useCachedQueries) {
///   // CachedFutureBuilder kullan
/// } else {
///   // Normal FutureBuilder kullan
/// }
/// ```
/// Saat Dilimi: Europe/Istanbul (UTC+3)
class FeatureFlags {
  FeatureFlags._();

  /// Riverpod state management kullanımı.
  /// true: Yeni Riverpod provider'ları kullanılır
  /// false: Eski ValueNotifier yapıları kullanılır
  /// **Etkilenen Alanlar:**
  /// - AuthStateProvider vs authStateNotifier
  /// - ThemeStateProvider vs themeModeNotifier
  /// - UserDataProvider vs userDataNotifier
  /// **Geçiş Planı:**
  /// - Phase 1: false (altyapı hazırlığı)
  /// - Phase 3: true (migration başlangıcı)
  /// - Phase 6: true (eski yapılar kaldırılır)
  static const bool useRiverpod = false;

  /// Cache mekanizması kullanımı.
  /// true: CachedFutureBuilder kullanılır
  /// false: Normal FutureBuilder kullanılır
  /// **Etkilenen Alanlar:**
  /// - WorkerListScreen
  /// - PaymentHistoryScreen
  /// - Diğer liste ekranları
  /// **Geçiş Planı:**
  /// - Phase 1-3: false
  /// - Phase 4: true (cache implementasyonu)
  /// - Phase 6: true (kalıcı)
  static const bool useCachedQueries = false;

  /// Optimize edilmiş ListView kullanımı.
  /// true: itemExtent ve diğer optimizasyonlar aktif
  /// false: Standart ListView kullanılır
  /// **Etkilenen Alanlar:**
  /// - WorkerListScreen ListView
  /// - PaymentHistoryScreen ListView
  /// - Diğer liste görünümleri
  /// **Optimizasyonlar:**
  /// - itemExtent parametresi
  /// - addAutomaticKeepAlives: false
  /// - addRepaintBoundaries: false (basit widget'lar için)
  /// - Const constructor'lar
  /// **Geçiş Planı:**
  /// - Phase 1-3: false
  /// - Phase 4: true (ListView optimizasyonları)
  /// - Phase 6: true (kalıcı)
  static const bool useOptimizedListViews = false;

  /// RPC fonksiyonları kullanımı (N+1 query çözümü).
  /// true: Supabase RPC fonksiyonları kullanılır
  /// false: Eski N+1 query implementasyonu kullanılır
  /// **Etkilenen Alanlar:**
  /// - WorkerService.getWorkersWithUnpaidDays()
  /// - PaymentService.getPaymentSummary()
  /// **Geçiş Planı:**
  /// - Phase 1-3: false
  /// - Phase 4: true (RPC implementasyonu)
  /// - Phase 6: true (kalıcı)
  static const bool useRpcFunctions = false;

  /// Image caching kullanımı.
  /// true: CachedNetworkImage kullanılır
  /// false: Standart Image.network kullanılır
  /// **Etkilenen Alanlar:**
  /// - Worker profile resimleri
  /// - Diğer network image'lar
  /// **Geçiş Planı:**
  /// - Phase 1-3: false
  /// - Phase 4: true (image caching)
  /// - Phase 6: true (kalıcı)
  static const bool useImageCaching = false;

  /// Yeni utility modülleri kullanımı.
  /// true: DateFormatter, CurrencyFormatter, SupabaseQueryBuilder kullanılır
  /// false: Eski helper fonksiyonlar kullanılır
  /// **Etkilenen Alanlar:**
  /// - Tüm service dosyaları (_formatDate, _formatAmount)
  /// - UI dosyaları (currency formatting)
  /// **Geçiş Planı:**
  /// - Phase 1: false (utility'ler oluşturuldu)
  /// - Phase 2: true (migration başlangıcı)
  /// - Phase 6: true (kalıcı)
  static const bool useNewUtilities = false;

  /// Merkezi error logging kullanımı.
  /// true: ErrorLogger singleton kullanılır
  /// false: debugPrint ve boş catch blokları kullanılır
  /// **Etkilenen Alanlar:**
  /// - Tüm service dosyaları
  /// - Error handling blokları
  /// **Geçiş Planı:**
  /// - Phase 1: false (ErrorLogger oluşturuldu)
  /// - Phase 2: true (migration başlangıcı)
  /// - Phase 6: true (kalıcı)
  static const bool useErrorLogger = false;

  /// Tüm yeni özelliklerin aktif olup olmadığını kontrol eder.
  /// Returns:
  /// - true: Tüm feature flag'ler aktif
  /// - false: En az bir feature flag pasif
  /// Örnek:
  /// ```dart
  /// if (FeatureFlags.isFullyMigrated) {
  ///   print('Tüm optimizasyonlar aktif!');
  /// }
  /// ```
  static bool get isFullyMigrated {
    return useRiverpod &&
        useCachedQueries &&
        useOptimizedListViews &&
        useRpcFunctions &&
        useImageCaching &&
        useNewUtilities &&
        useErrorLogger;
  }

  /// Aktif feature flag'lerin sayısını döndürür.
  /// Returns:
  /// - int: Aktif flag sayısı (0-7 arası)
  /// Örnek:
  /// ```dart
  /// final activeCount = FeatureFlags.activeFeatureCount;
  /// print('$activeCount / 7 özellik aktif');
  /// ```
  static int get activeFeatureCount {
    int count = 0;
    if (useRiverpod) count++;
    if (useCachedQueries) count++;
    if (useOptimizedListViews) count++;
    if (useRpcFunctions) count++;
    if (useImageCaching) count++;
    if (useNewUtilities) count++;
    if (useErrorLogger) count++;
    return count;
  }

  /// Migration ilerleme yüzdesini döndürür.
  /// Returns:
  /// - double: İlerleme yüzdesi (0.0 - 1.0 arası)
  /// Örnek:
  /// ```dart
  /// final progress = FeatureFlags.migrationProgress;
  /// print('Migration %${(progress * 100).toStringAsFixed(0)} tamamlandı');
  /// ```
  static double get migrationProgress {
    return activeFeatureCount / 7.0;
  }
}
