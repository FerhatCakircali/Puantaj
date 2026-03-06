# Implementation Plan: Flutter Puantaj Uygulaması Optimizasyonu

## Genel Bakış

Bu implementation plan, Flutter Puantaj uygulamasının 6 fazlı optimizasyon sürecini kapsar. Her faz, state management modernizasyonu, kod kalitesi iyileştirmeleri, performans optimizasyonları ve dependency temizliğini içerir. Tüm görevler test edilebilir, geri alınabilir ve kademeli olarak uygulanabilir şekilde tasarlanmıştır.

**Kritik İlkeler:**
- Her görev bağımsız olarak test edilebilir
- Backward compatibility korunur
- Feature flag pattern ile kontrollü geçiş
- Her faz sonunda checkpoint

**Kod Standartları:**
- ✅ **Tüm kod açıklamaları ve dokümantasyon Türkçe olmalıdır**
- ✅ **Tüm tarih ve saat işlemleri Türkiye İstanbul saat diliminde (Europe/Istanbul, UTC+3) olmalıdır**
- ✅ **Dartdoc comment'leri Türkçe yazılmalıdır**
- ✅ **Kod örnekleri ve açıklamalar Türkçe olmalıdır**

**Tahmini Süre:** 6 hafta (30 iş günü)

## Tasks

### Phase 1: Hazırlık ve Altyapı (Hafta 1)

- [x] 1. Utility modüllerini oluştur
  - [x] 1.1 DateFormatter utility'sini oluştur
    - `lib/utils/date_formatter.dart` dosyasını oluştur
    - `toIso8601Date()`, `fromIso8601Date()`, `toDisplayDate()`, `toShortDate()` metodlarını implement et
    - ISO 8601 formatı (YYYY-MM-DD) kullan
    - _Requirements: 1.1, 1.7_
    - _Estimated time: 2 hours_
  
  - [x]* 1.2 DateFormatter için unit testler yaz
    - `test/utils/date_formatter_test.dart` dosyasını oluştur
    - Minimum 10 test case yaz (format, parse, edge cases)
    - Tek haneli ay/gün padding testleri
    - _Requirements: 12.2_
    - _Estimated time: 2 hours_

  - [x] 1.3 CurrencyFormatter utility'sini oluştur
    - `lib/utils/currency_formatter.dart` dosyasını oluştur
    - `format()`, `formatWithoutSymbol()` metodlarını implement et
    - Türk lirası formatı (binlik ayırıcı nokta) kullan
    - _Requirements: 1.2, 1.8_
    - _Estimated time: 1.5 hours_
  
  - [x]* 1.4 CurrencyFormatter için unit testler yaz
    - `test/utils/currency_formatter_test.dart` dosyasını oluştur
    - Minimum 5 test case yaz (binlik ayırıcı, ondalık, sembol)
    - _Requirements: 12.3_
    - _Estimated time: 1 hour_
  
  - [x] 1.5 SupabaseQueryBuilder utility'sini oluştur
    - `lib/utils/supabase_query_builder.dart` dosyasını oluştur
    - `forUser()`, `dateRange()` helper metodlarını implement et
    - Standardize edilmiş query pattern'leri sağla
    - _Requirements: 1.3_
    - _Estimated time: 2 hours_

- [x] 2. Error handling altyapısını oluştur
  - [x] 2.1 ErrorLogger singleton'ını implement et
    - `lib/core/error_logger.dart` dosyasını oluştur
    - `logError()`, `logWarning()`, `logInfo()` metodlarını implement et
    - Context, error object ve stack trace parametreleri ekle
    - Emoji indicator'lar ekle (❌, ⚠️, ℹ️)
    - _Requirements: 1.4, 1.9, 10.1, 10.2, 10.4_
    - _Estimated time: 2 hours_
  
  - [ ]* 2.2 ErrorLogger için unit testler yaz
    - `test/core/error_logger_test.dart` dosyasını oluştur
    - Mock verification ile test et
    - _Requirements: 12.4_
    - _Estimated time: 1.5 hours_

- [x] 3. Riverpod provider altyapısını oluştur (henüz kullanma)
  - [x] 3.1 AuthStateProvider'ı oluştur
    - `lib/core/providers/auth_provider.dart` dosyasını oluştur
    - StateNotifier ile bool state yönet
    - `login()` ve `logout()` metodlarını implement et
    - Henüz mevcut authStateNotifier'ı değiştirme
    - _Requirements: 1.5, 4.1, 4.2_
    - _Estimated time: 1.5 hours_
  
  - [x] 3.2 ThemeStateProvider'ı oluştur
    - `lib/core/providers/theme_provider.dart` dosyasını oluştur
    - StateNotifier ile ThemeMode state yönet
    - SharedPreferences'tan tema yükle
    - `setTheme()` metodu ile tema kaydet
    - _Requirements: 1.5, 3.1, 3.3, 3.5_
    - _Estimated time: 2 hours_
  
  - [x] 3.3 UserDataProvider'ı oluştur
    - `lib/core/providers/user_data_provider.dart` dosyasını oluştur
    - StateNotifier ile Map<String, dynamic>? state yönet
    - `setUserData()`, `clearUserData()`, `isAdmin` getter implement et
    - _Requirements: 1.5, 5.1, 5.2, 5.4, 5.10_
    - _Estimated time: 1.5 hours_
  
  - [ ]* 3.4 Provider'lar için widget testler yaz
    - `test/providers/auth_provider_test.dart` oluştur
    - `test/providers/theme_provider_test.dart` oluştur
    - `test/providers/user_data_provider_test.dart` oluştur
    - State değişikliklerini doğrula
    - _Requirements: 12.5, 12.9_
    - _Estimated time: 2 hours_

- [x] 4. Feature flag sistemini ekle
  - [x] 4.1 FeatureFlags configuration class'ını oluştur
    - `lib/config/feature_flags.dart` dosyasını oluştur
    - `useRiverpod`, `useCachedQueries`, `useOptimizedListViews` flag'lerini ekle
    - Static const bool değerler kullan
    - _Requirements: 1.6, 14.2, 14.3_
    - _Estimated time: 1 hour_

- [x] 5. Checkpoint - Phase 1 tamamlandı
  - Tüm testlerin geçtiğini doğrula
  - `flutter analyze` çalıştır (0 error, 0 warning)
  - Kullanıcıya sorular varsa sor
  - _Estimated time: 30 minutes_

### Phase 2: Kod Tekrarı Eliminasyonu (Hafta 2)

- [x] 6. Service dosyalarında _formatDate() migrasyonu
  - [x] 6.1 worker_service.dart'ta _formatDate() kullanımını değiştir
    - `_formatDate()` fonksiyonunu kaldır
    - Tüm kullanımları `DateFormatter.toIso8601Date()` ile değiştir
    - Import ekle: `import '../utils/date_formatter.dart';`
    - _Requirements: 2.1, 2.3, 2.11_
    - _Estimated time: 1 hour_
  
  - [x] 6.2 payment_service.dart'ta _formatDate() kullanımını değiştir
    - `_formatDate()` fonksiyonunu kaldır
    - Tüm kullanımları `DateFormatter.toIso8601Date()` ile değiştir
    - _Requirements: 2.1, 2.4, 2.11_
    - _Estimated time: 1 hour_
  
  - [x] 6.3 attendance_service.dart'ta _formatDate() kullanımını değiştir
    - `_formatDate()` fonksiyonunu kaldır
    - Tüm kullanımları `DateFormatter.toIso8601Date()` ile değiştir
    - _Requirements: 2.1, 2.5, 2.11_
    - _Estimated time: 1 hour_
  
  - [x] 6.4 advance_service.dart'ta _formatDate() kullanımını değiştir
    - `_formatDate()` fonksiyonunu kaldır
    - Tüm kullanımları `DateFormatter.toIso8601Date()` ile değiştir
    - _Requirements: 2.1, 2.6, 2.11_
    - _Estimated time: 1 hour_
  
  - [x] 6.5 expense_service.dart'ta _formatDate() kullanımını değiştir
    - `_formatDate()` fonksiyonunu kaldır
    - Tüm kullanımları `DateFormatter.toIso8601Date()` ile değiştir
    - _Requirements: 2.1, 2.7, 2.11_
    - _Estimated time: 1 hour_
  
  - [x] 6.6 report_service.dart'ta _formatDate() kullanımını değiştir
    - `_formatDate()` fonksiyonunu kaldır
    - Tüm kullanımları `DateFormatter.toIso8601Date()` ile değiştir
    - _Requirements: 2.1, 2.8, 2.11_
    - _Estimated time: 1 hour_

- [x] 7. Currency formatting migrasyonu
  - [x] 7.1 payment_service.dart'ta _formatAmount() kullanımını değiştir
    - `_formatAmount()` fonksiyonunu kaldır
    - Tüm kullanımları `CurrencyFormatter.format()` ile değiştir
    - Import ekle: `import '../utils/currency_formatter.dart';`
    - _Requirements: 2.2_
    - _Estimated time: 1 hour_
  
  - [x] 7.2 UI dosyalarında currency formatting'i güncelle
    - Payment ekranlarında CurrencyFormatter kullan
    - Report ekranlarında CurrencyFormatter kullan
    - Tutarlı format sağla
    - _Requirements: 2.2_
    - _Estimated time: 2 hours_

- [x] 8. Error handling standardizasyonu
  - [x] 8.1 worker_service.dart'ta error handling'i iyileştir
    - Boş catch bloklarını ErrorLogger ile doldur
    - Null assertion (!) yerine null-aware operatörler (??, ?.) kullan
    - Context bilgisi ile error logla
    - _Requirements: 2.9, 2.10, 2.12, 10.3, 10.6, 10.7, 10.8_
    - _Estimated time: 1.5 hours_
  
  - [x] 8.2 payment_service.dart'ta error handling'i iyileştir
    - Boş catch bloklarını ErrorLogger ile doldur
    - Null-aware operatörler kullan
    - _Requirements: 2.9, 2.10, 2.12, 10.3_
    - _Estimated time: 1.5 hours_
  
  - [x] 8.3 attendance_service.dart'ta error handling'i iyileştir
    - Boş catch bloklarını ErrorLogger ile doldur
    - Null-aware operatörler kullan
    - _Requirements: 2.9, 2.10, 2.12, 10.3_
    - _Estimated time: 1.5 hours_
  
  - [x] 8.4 Diğer service dosyalarında error handling'i iyileştir
    - advance_service.dart, expense_service.dart, report_service.dart
    - Tutarlı error handling pattern uygula
    - _Requirements: 2.9, 2.10, 2.12, 10.3, 10.9_
    - _Estimated time: 2 hours_

- [ ]* 9. Service integration testleri
  - [ ]* 9.1 Her service için integration test yaz
    - `test/integration/worker_service_test.dart` oluştur
    - `test/integration/payment_service_test.dart` oluştur
    - API response formatlarını doğrula
    - Date/currency formatting tutarlılığını test et
    - _Requirements: 12.6, 12.10_
    - _Estimated time: 3 hours_

- [x] 10. Checkpoint - Phase 2 tamamlandı
  - Tüm testlerin geçtiğini doğrula
  - API çağrılarının aynı sonucu verdiğini kontrol et
  - `flutter analyze` çalıştır
  - Kullanıcıya sorular varsa sor
  - _Estimated time: 30 minutes_

### Phase 3: State Management Migrasyonu (Hafta 3-4)

- [x] 11. ProviderScope ile app'i sar
  - [x] 11.1 main.dart'ta ProviderScope ekle
    - `runApp(ProviderScope(child: MyApp()));` ile sar
    - flutter_riverpod import ekle
    - _Requirements: 3.1_
    - _Estimated time: 30 minutes_
    - ✅ TAMAMLANDI: main.dart satır 62'de ProviderScope ile sarmalandı

- [x] 12. Theme provider migrasyonu
  - [x] 12.1 MyApp widget'ını ConsumerWidget'a dönüştür
    - `class MyApp extends ConsumerWidget` yap
    - `build(BuildContext context, WidgetRef ref)` signature kullan
    - _Requirements: 3.6_
    - _Estimated time: 1 hour_
    - ✅ TAMAMLANDI: MyApp ConsumerStatefulWidget'a dönüştürüldü (main.dart satır 65-68)
  
  - [x] 12.2 ThemeStateProvider'ı kullan
    - `ref.watch(themeStateProvider)` ile tema al
    - ValueListenableBuilder'ı kaldır
    - themeModeNotifier'ı henüz kaldırma (backward compatibility)
    - _Requirements: 3.2, 3.6, 3.7_
    - _Estimated time: 1.5 hours_
    - ✅ TAMAMLANDI: ref.watch(themeStateProvider) kullanılıyor (main.dart satır 327), ValueListenableBuilder kaldırıldı
  
  - [x] 12.3 Tema değiştirme fonksiyonlarını güncelle
    - Settings ekranında `ref.read(themeStateProvider.notifier).setTheme()` kullan
    - SharedPreferences persist işlemini provider'a taşı
    - _Requirements: 3.4, 3.5_
    - _Estimated time: 1 hour_
    - ✅ TAMAMLANDI: ThemeStateProvider SharedPreferences ile entegre (theme_provider.dart)

  - [ ]* 12.4 Theme değişikliği testleri
    - Widget rebuild testleri yaz
    - Tema persist testleri yaz
    - _Requirements: 3.8, 3.9_
    - _Estimated time: 1.5 hours_

- [x] 13. Auth provider migrasyonu
  - [x] 13.1 Bootstrap session'da AuthStateProvider kullan
    - `_bootstrapSession()` fonksiyonunda `ref.read(authStateProvider.notifier)` kullan
    - Login durumunda `login()` çağır
    - Logout durumunda `logout()` çağır
    - authStateNotifier'ı henüz kaldırma
    - _Requirements: 4.3, 4.5, 4.6_
    - _Estimated time: 2 hours_
    - ✅ TAMAMLANDI: Bootstrap'ta AuthStateProvider kullanılıyor (main.dart satır 119, 127, 138, 147)
  
  - [x] 13.2 Router initialization'da AuthStateProvider kullan
    - `_initializeRouter()` fonksiyonunda `ref.read(authStateProvider)` kulan
    - Auth state değişikliklerini dinle: `ref.listen<bool>(authStateProvider, ...)`
    - Router'ı auth state'e göre yeniden oluştur
    - _Requirements: 4.4, 4.7_
    - _Estimated time: 2 hours_
    - ✅ TAMAMLANDI: ref.listen ile auth state dinleniyor (main.dart satır 329-331)
  
  - [x] 13.3 Worker session kontrolünü güncelle
    - Worker session tespit edildiğinde auth state false yap
    - User session valid ise auth state true yap
    - _Requirements: 4.8, 4.9_
    - _Estimated time: 1 hour_
    - ✅ TAMAMLANDI: Worker session kontrolü AuthStateProvider ile entegre (main.dart satır 119)
  
  - [ ]* 13.4 Login/logout flow testleri
    - Login flow test et
    - Logout flow test et
    - Router navigation testleri
    - _Requirements: 12.9_
    - _Estimated time: 2 hours_

- [x] 14. UserData provider migrasyonu
  - [x] 14.1 Bootstrap'ta UserDataProvider kullan
    - User session yüklendiğinde `ref.read(userDataProvider.notifier).setUserData()` çağır
    - Logout'ta `clearUserData()` çağır
    - userDataNotifier'ı henüz kaldırma
    - _Requirements: 5.2, 5.3, 5.9_
    - _Estimated time: 1.5 hours_

  - [x] 14.2 Admin kontrollerini UserDataProvider ile yap
    - Router'da `ref.read(userDataProvider.notifier).isAdmin` kullan
    - Admin ekranlarında isAdmin getter kullan
    - _Requirements: 5.4, 5.5_
    - _Estimated time: 1 hour_
  
  - [x] 14.3 Null user data handling
    - UserDataProvider state null ise isAdmin false döndür
    - Graceful error handling ekle
    - _Requirements: 5.9, 5.10_
    - _Estimated time: 1 hour_
  
  - [ ]* 14.4 UserData state değişikliği testleri
    - State update testleri
    - isAdmin getter testleri
    - Null handling testleri
    - _Requirements: 5.6, 5.7_
    - _Estimated time: 1.5 hours_

- [x] 15. Eski ValueNotifier'ları kaldır
  - [x] 15.1 app_globals.dart'tan ValueNotifier'ları sil
    - authStateNotifier'ı kaldır
    - themeModeNotifier'ı kaldır
    - Tüm referansları temizle
    - _Requirements: 3.10, 4.10_
    - _Estimated time: 1 hour_
  
  - [x] 15.2 user_data_notifier.dart dosyasını deprecated olarak işaretle
    - Service katmanı hala kullanıyor (auth_login_mixin, app_bootstrap)
    - UI katmanı tamamen UserDataProvider kullanıyor
    - main.dart'ta otomatik senkronizasyon yapılıyor
    - _Requirements: 5.8_
    - _Estimated time: 30 minutes_

- [x] 16. Checkpoint - Phase 3 tamamlandı
  - Tüm testlerin geçtiğini doğrula
  - Login/logout flow'u manuel test et
  - Tema değişikliğini test et
  - Admin/user role değişikliğini test et
  - `flutter analyze` çalıştır
  - Kullanıcıya sorular varsa sor
  - _Estimated time: 1 hour_

### Phase 4: Performans İyileştirmeleri (Hafta 5)

- [x] 17. Cache mekanizması implementasyonu
  - [x] 17.1 CachedFutureBuilder widget'ını oluştur
    - `lib/utils/cached_future_builder.dart` dosyasını oluştur
    - Generic type support ekle: `CachedFutureBuilder<T>`
    - Cache duration parametresi ekle (default 5 dakika)
    - Cache timestamp ile freshness kontrolü
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.7, 6.9, 6.10_
    - _Estimated time: 3 hours_
  
  - [x] 17.2 WorkerListScreen'de CachedFutureBuilder kullan
    - Mevcut FutureBuilder'ı CachedFutureBuilder ile değiştir
    - Cache duration 5 dakika olarak ayarla
    - _Requirements: 6.5, 6.8_
    - _Estimated time: 1 hour_
  
  - [x] 17.3 PaymentHistoryScreen'de CachedFutureBuilder kullan
    - Mevcut FutureBuilder'ı CachedFutureBuilder ile değiştir
    - Cache duration 5 dakika olarak ayarla
    - _Requirements: 6.6, 6.8_
    - _Estimated time: 1 hour_

- [x] 18. ListView optimizasyonları
  - [x] 18.1 WorkerListScreen ListView'ını optimize et
    - `itemExtent: 80.0` parametresi ekle
    - `addAutomaticKeepAlives: false` ekle
    - `addRepaintBoundaries: false` ekle (basit widget'lar için)
    - Const constructor'lar kullan
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.7, 7.8, 7.9_
    - _Estimated time: 1.5 hours_
  
  - [x] 18.2 PaymentHistoryScreen ListView'ını optimize et
    - Uygun itemExtent değeri belirle
    - Optimizasyon parametrelerini ekle
    - _Requirements: 7.1, 7.2, 7.3, 7.5, 7.7_
    - _Estimated time: 1.5 hours_
  
  - [ ]* 18.3 Scroll performance testleri
    - Flutter DevTools ile FPS ölç
    - 60 FPS hedefini doğrula
    - Önce/sonra karşılaştırması yap
    - _Requirements: 7.6, 7.10, 13.3, 13.10_
    - _Estimated time: 2 hours_

- [x] 19. N+1 query çözümü - Supabase RPC fonksiyonları
  - [x] 19.1 get_workers_with_unpaid_days RPC fonksiyonunu oluştur
    - Supabase SQL Editor'da RPC fonksiyonu yaz
    - Workers, attendance ve paid_days tablolarını JOIN et
    - Unpaid full days ve half days sayısını hesapla
    - user_id parametresi ile filtrele
    - _Requirements: 8.1, 8.2, 8.5, 8.9_
    - _Estimated time: 2 hours_
  
  - [x] 19.2 get_payment_summary RPC fonksiyonunu oluştur
    - Supabase SQL Editor'da RPC fonksiyonu yaz
    - Date range parametreleri ekle (start_date, end_date)
    - Payment summary verilerini aggregate et
    - _Requirements: 8.3, 8.4, 8.5_
    - _Estimated time: 2 hours_
  
  - [x] 19.3 WorkerService'te RPC fonksiyonlarını kullan
    - `getWorkersWithUnpaidDays()` metodunu RPC ile değiştir
    - Response'u Dart model'e map et
    - Eski N+1 query implementasyonunu kaldır
    - _Requirements: 8.6, 8.7, 8.8, 8.10_
    - _Estimated time: 2 hours_
  
  - [x] 19.4 PaymentService'te RPC fonksiyonlarını kullan
    - `getPaymentSummary()` metodunu RPC ile değiştir
    - Response'u Dart model'e map et
    - _Requirements: 8.6, 8.8_
    - _Estimated time: 1.5 hours_
  
  - [ ]* 19.5 RPC fonksiyonları için testler
    - Staging environment'ta RPC test et
    - Eski query sonuçları ile karşılaştır
    - Query count'u doğrula (15+ → 1-2)
    - _Requirements: 8.9, 13.5_
    - _Estimated time: 2 hours_

- [ ] 20. Image caching implementasyonu
  - [ ] 20.1 cached_network_image paketini ekle
    - pubspec.yaml'a `cached_network_image: ^3.3.1` ekle
    - `flutter pub get` çalıştır
    - _Requirements: 9.1, 11.4_
    - _Estimated time: 15 minutes_

  - [ ] 20.2 Profile resimlerinde CachedNetworkImage kullan
    - Worker profile resimlerini CachedNetworkImage ile değiştir
    - Placeholder widget ekle (loading state)
    - Error widget ekle (load failure)
    - Cache duration yapılandır
    - _Requirements: 9.2, 9.3, 9.4, 9.5, 9.6, 9.7_
    - _Estimated time: 2 hours_
  
  - [ ] 20.3 Cache temizleme mekanizması
    - App başlangıcında expired cache'leri temizle
    - Cache size limiti ayarla
    - _Requirements: 9.8, 9.9_
    - _Estimated time: 1 hour_
  
  - [ ]* 20.4 Network bandwidth testleri
    - Tekrarlanan image load'ları test et
    - Network usage azalmasını doğrula
    - _Requirements: 9.10_
    - _Estimated time: 1 hour_

- [ ]* 21. Performance profiling ve metrik toplama
  - [ ]* 21.1 Baseline metrikleri kaydet
    - Flutter DevTools Performance tab kullan
    - App startup time ölç
    - Screen build time ölç
    - Memory usage ölç
    - Network request count say
    - _Requirements: 13.10, 13.11_
    - _Estimated time: 2 hours_
  
  - [ ]* 21.2 Optimizasyon sonrası metrikleri kaydet
    - Aynı metrikleri tekrar ölç
    - Önce/sonra karşılaştırması yap
    - İyileşme yüzdelerini hesapla
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7, 13.8, 13.9, 13.12_
    - _Estimated time: 2 hours_

- [ ] 22. Checkpoint - Phase 4 tamamlandı
  - Tüm testlerin geçtiğini doğrula
  - Performance metriklerini gözden geçir
  - Cache mekanizmasını manuel test et
  - RPC fonksiyonlarının doğru çalıştığını kontrol et
  - `flutter analyze` çalıştır
  - Kullanıcıya sorular varsa sor
  - _Estimated time: 1 hour_

### Phase 5: Dependency Yönetimi ve Temizlik (Hafta 6)

- [ ] 23. Kullanılmayan paketleri kaldır
  - [ ] 23.1 pubspec.yaml backup'ı al
    - Mevcut pubspec.yaml'ı yedekle
    - _Requirements: 14.12_
    - _Estimated time: 5 minutes_
  
  - [ ] 23.2 Kullanılmayan paketleri kaldır
    - `riverpod_annotation: ^4.0.2` kaldır (code generation kullanılmıyor)
    - `googleapis: ^15.0.0` kaldır (kullanılmıyor)
    - `googleapis_auth: ^2.0.0` kaldır (kullanılmıyor)
    - _Requirements: 11.1, 11.2, 11.3_
    - _Estimated time: 15 minutes_

- [ ] 24. Eksik paketleri ekle
  - [ ] 24.1 Yeni paketleri pubspec.yaml'a ekle
    - `cached_network_image: ^3.3.1` ekle (zaten 20.1'de eklendi)
    - `connectivity_plus: ^6.0.5` ekle (network durumu kontrolü)
    - _Requirements: 11.4, 11.5_
    - _Estimated time: 10 minutes_
  
  - [ ] 24.2 flutter pub get çalıştır
    - Dependency'leri indir
    - Hata olmadığını doğrula
    - _Requirements: 11.6_
    - _Estimated time: 5 minutes_

- [ ] 25. Import temizliği ve static analysis
  - [ ] 25.1 Kullanılmayan import'ları kaldır
    - Tüm Dart dosyalarında unused import'ları temizle
    - IDE'nin "Optimize Imports" özelliğini kullan
    - _Requirements: 11.8, 15.4_
    - _Estimated time: 1 hour_
  
  - [ ] 25.2 flutter analyze çalıştır ve düzelt
    - `flutter analyze` komutunu çalıştır
    - Tüm error'ları düzelt
    - Tüm warning'leri düzelt
    - _Requirements: 11.7, 15.1, 15.2_
    - _Estimated time: 2 hours_

- [ ] 26. Code quality iyileştirmeleri
  - [ ] 26.1 Naming convention'ları kontrol et
    - Tutarlı naming kullanıldığını doğrula
    - Anlamlı değişken/fonksiyon isimleri
    - _Requirements: 15.4, 15.9_
    - _Estimated time: 1 hour_
  
  - [ ] 26.2 Const constructor'ları ekle
    - Mümkün olan yerlerde const constructor kullan
    - Performance için optimize et
    - _Requirements: 15.6_
    - _Estimated time: 1.5 hours_
  
  - [ ] 26.3 Dartdoc comment'leri ekle
    - Public API'lar için documentation yaz
    - Utility fonksiyonlarını dokümante et
    - Provider'ları dokümante et
    - _Requirements: 15.5_
    - _Estimated time: 2 hours_
  
  - [ ] 26.4 Code formatting kontrolü
    - `dart format .` çalıştır
    - Flutter style guide'a uygunluğu kontrol et
    - _Requirements: 15.7_
    - _Estimated time: 30 minutes_

- [ ] 27. Build testleri
  - [ ] 27.1 Android build testi
    - `flutter build apk` çalıştır
    - Build başarılı olmalı
    - _Requirements: 11.9_
    - _Estimated time: 30 minutes_
  
  - [ ] 27.2 iOS build testi
    - `flutter build ios` çalıştır (Mac gerekli)
    - Build başarılı olmalı
    - _Requirements: 11.10_
    - _Estimated time: 30 minutes_

- [ ]* 28. Test coverage kontrolü
  - [ ]* 28.1 Test coverage raporu oluştur
    - `flutter test --coverage` çalıştır
    - Coverage raporunu incele
    - Minimum %70 coverage hedefle
    - _Requirements: 12.1_
    - _Estimated time: 1 hour_

### Phase 6: Dokümantasyon ve Final Deployment

- [ ] 29. Dokümantasyon güncellemeleri
  - [ ] 29.1 README.md güncelle
    - State management yaklaşımını (Riverpod) dokümante et
    - Yeni utility fonksiyonlarını açıkla
    - Performance best practices ekle
    - _Estimated time: 1.5 hours_
  
  - [ ] 29.2 ARCHITECTURE.md oluştur
    - Klasör yapısını dokümante et
    - Provider pattern'i açıkla
    - Service layer mimarisini açıkla
    - Error handling yaklaşımını dokümante et
    - _Estimated time: 2 hours_
  
  - [ ] 29.3 MIGRATION_GUIDE.md oluştur
    - ValueNotifier → Riverpod geçiş rehberi
    - Utility fonksiyonları kullanım örnekleri
    - Breaking changes listesi
    - _Estimated time: 1.5 hours_
  
  - [ ] 29.4 PERFORMANCE.md oluştur
    - Performans metrikleri (önce/sonra)
    - Optimization teknikleri
    - Profiling rehberi
    - _Estimated time: 1 hour_
  
  - [ ] 29.5 CHANGELOG.md güncelle
    - Tüm dependency değişikliklerini kaydet
    - Major değişiklikleri listele
    - Version bilgisi ekle
    - _Requirements: 11.12_
    - _Estimated time: 1 hour_

- [ ] 30. Staging deployment ve test
  - [ ] 30.1 Staging environment'a deploy et
    - Feature flag'leri disabled olarak deploy et
    - Database migration'ları çalıştır (RPC fonksiyonları)
    - _Requirements: 14.6, 14.7_
    - _Estimated time: 1 hour_
  
  - [ ] 30.2 Staging'de kapsamlı test
    - Tüm kritik flow'ları test et (login, logout, payment, attendance)
    - Performance metriklerini ölç
    - Error logging'i kontrol et
    - Minimum 24 saat staging'de beklet
    - _Requirements: 14.6, 14.9_
    - _Estimated time: 3 hours_

- [ ] 31. Production deployment
  - [ ] 31.1 Production'a deploy et
    - Low-traffic saatlerinde deploy et (22:00 sonrası)
    - Feature flag'leri disabled olarak başlat
    - Database backup al
    - _Requirements: 14.1, 14.7_
    - _Estimated time: 1 hour_
  
  - [ ] 31.2 Feature flag'leri kademeli olarak aç
    - İlk gün: %10 kullanıcı
    - İkinci gün: %50 kullanıcı
    - Üçüncü gün: %100 kullanıcı
    - Her adımda monitoring yap
    - _Requirements: 14.8_
    - _Estimated time: 3 days (monitoring)_
  
  - [ ] 31.3 Production monitoring
    - Error rate'i izle
    - Performance metriklerini izle
    - User feedback topla
    - Sorun varsa rollback planını uygula
    - _Requirements: 14.11_
    - _Estimated time: Ongoing_

- [ ] 32. Final checkpoint - Proje tamamlandı
  - Tüm success criteria'ları kontrol et
  - Performance iyileştirmelerini doğrula (startup %20+, memory %15+, network %80+)
  - Test coverage %70+ olduğunu doğrula
  - flutter analyze 0 error, 0 warning
  - Tüm dokümantasyon tamamlandı
  - Production'da stabil çalışıyor
  - Kullanıcıya final rapor sun
  - _Estimated time: 2 hours_

## Notes

### Task İşaretleme Kuralları
- `[ ]` - Tamamlanmamış görev
- `[x]` - Tamamlanmış görev
- `[ ]*` - Opsiyonel görev (test görevleri, hızlı MVP için atlanabilir)

### Dependency Haritası
- Phase 1 → Phase 2 (Utility'ler hazır olmalı)
- Phase 1 → Phase 3 (Provider'lar oluşturulmuş olmalı)
- Phase 3 → Phase 4 (State management stabil olmalı)
- Phase 4 → Phase 5 (Performance iyileştirmeleri tamamlanmalı)
- Phase 5 → Phase 6 (Dependency temizliği tamamlanmalı)

### Rollback Stratejisi
Her phase için ayrı Git branch kullanılmalı:
- `feature/optimization-phase-1`
- `feature/optimization-phase-2`
- `feature/optimization-phase-3`
- `feature/optimization-phase-4`
- `feature/optimization-phase-5`
- `feature/optimization-phase-6`

Sorun çıkarsa:
1. Feature flag'i kapat
2. Git commit'i revert et
3. Eski implementasyona geri dön
4. Maximum 15 dakika içinde rollback tamamlanmalı

### Test Stratejisi
- Unit testler: Her utility ve provider için
- Widget testler: Provider state değişiklikleri için
- Integration testler: Service refactoring sonrası
- Performance testler: Her optimizasyon sonrası
- Minimum %70 test coverage hedefi

### Performance Hedefleri
- App startup time: 2.5s → 1.8s (%28 iyileşme)
- Home screen build: 800ms → 400ms (%50 iyileşme)
- List scroll FPS: 45 → 60 FPS (%33 iyileşme)
- Memory usage: 180MB → 140MB (%22 azalma)
- Network requests: 15+ → 1-2 (%93 azalma)

### Kritik Başarı Kriterleri
1. ✅ Tüm ValueNotifier'lar Riverpod'a dönüştürülmüş
2. ✅ Kod tekrarı %80 azalmış
3. ✅ Test coverage %70+
4. ✅ flutter analyze 0 error, 0 warning
5. ✅ Performance hedefleri tutturulmuş
6. ✅ Hiçbir özellik bozulmamış
7. ✅ Zero downtime deployment
8. ✅ Rollback planı hazır ve test edilmiş

### Tahmini Toplam Süre
- Phase 1: 5 gün (40 saat)
- Phase 2: 5 gün (40 saat)
- Phase 3: 10 gün (80 saat)
- Phase 4: 5 gün (40 saat)
- Phase 5: 3 gün (24 saat)
- Phase 6: 2 gün (16 saat)
- **Toplam: 30 iş günü (6 hafta)**

### İletişim ve Onay Süreci
- Her phase sonunda checkpoint
- Code review her major değişiklik için
- Staging test minimum 24 saat
- Production deployment stakeholder onayı ile
- Sorun durumunda immediate rollback

## Referanslar
- Design Document: `.kiro/specs/flutter-app-optimization/design.md`
- Requirements Document: `.kiro/specs/flutter-app-optimization/requirements.md`
- Flutter Riverpod Documentation: https://riverpod.dev
- Flutter Performance Best Practices: https://flutter.dev/docs/perf
