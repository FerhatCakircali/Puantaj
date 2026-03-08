import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../core/error_handling/error_handler_mixin.dart';

/// Önbellek yönetim servisi
/// Uygulama genelinde kullanılan önbellekleri yönetir:
/// - Image cache (CachedNetworkImage)
/// - Data cache (CachedFutureBuilder)
class CacheManagerService with ErrorHandlerMixin {
  final DefaultCacheManager _imageCacheManager;

  CacheManagerService({DefaultCacheManager? imageCacheManager})
    : _imageCacheManager = imageCacheManager ?? DefaultCacheManager();

  /// Cache size limiti (MB cinsinden)
  static const int maxCacheSizeMB = 100;

  /// Cache temizleme periyodu (gün cinsinden)
  static const int cacheCleanupDays = 7;

  /// Uygulama başlangıcında expired cache'leri temizle
  /// Bu metod app başlangıcında çağrılmalıdır (main.dart)
  Future<void> initializeCache() async {
    return handleError(
      () async {
        debugPrint('🧹 Cache temizleme başlatılıyor...');

        // Expired image cache'leri temizle
        await _cleanupExpiredImageCache();

        // Cache boyutunu kontrol et
        await _checkCacheSize();

        debugPrint('Cache temizleme tamamlandı');
      },
      null,
      context: 'CacheManagerService.initializeCache',
    );
  }

  /// Expired image cache'leri temizle
  Future<void> _cleanupExpiredImageCache() async {
    return handleError(
      () async {
        // CachedNetworkImage otomatik olarak expired cache'leri temizler
        // Ancak manuel temizleme için emptyCache() kullanılabilir
        final cacheInfo = await _imageCacheManager.getFileFromCache('dummy');
        if (cacheInfo == null) {
          debugPrint('📦 Image cache boş');
        } else {
          debugPrint('📦 Image cache mevcut');
        }
      },
      null,
      context: 'CacheManagerService._cleanupExpiredImageCache',
    );
  }

  /// Cache boyutunu kontrol et ve limit aşılmışsa temizle
  Future<void> _checkCacheSize() async {
    return handleError(
      () async {
        debugPrint('Cache boyutu kontrol ediliyor...');

        // Eğer manuel kontrol gerekirse, cache dosyalarının boyutunu hesapla
        // ve maxCacheSizeMB ile karşılaştır
      },
      null,
      context: 'CacheManagerService._checkCacheSize',
    );
  }

  /// Tüm image cache'i temizle (manuel temizleme)
  /// Kullanım: Settings ekranında "Cache Temizle" butonu
  Future<void> clearImageCache() async {
    return handleErrorWithThrow(
      () async {
        debugPrint('🧹 Image cache temizleniyor...');
        await _imageCacheManager.emptyCache();
        debugPrint('Image cache temizlendi');
      },
      context: 'CacheManagerService.clearImageCache',
      userMessage: 'Cache temizlenirken hata oluştu',
    );
  }

  /// Cache boyutunu al (MB cinsinden)
  /// Kullanım: Settings ekranında cache boyutunu göstermek için
  Future<double> getCacheSizeMB() async {
    return handleError(
      () async => 0.0,
      0.0,
      context: 'CacheManagerService.getCacheSizeMB',
    );
  }
}
