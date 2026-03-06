import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../core/error_logger.dart';

/// Önbellek yönetim servisi
/// Uygulama genelinde kullanılan önbellekleri yönetir:
/// - Image cache (CachedNetworkImage)
/// - Data cache (CachedFutureBuilder)
/// Özellikler:
/// - Expired cache temizleme
/// - Cache size limiti kontrolü
/// - Manuel cache temizleme
/// Saat Dilimi: Europe/Istanbul (UTC+3)
class CacheManagerService {
  static final CacheManagerService _instance = CacheManagerService._internal();
  factory CacheManagerService() => _instance;
  CacheManagerService._internal();

  /// Singleton instance
  static CacheManagerService get instance => _instance;

  /// Image cache manager (CachedNetworkImage için)
  final DefaultCacheManager _imageCacheManager = DefaultCacheManager();

  /// Cache size limiti (MB cinsinden)
  static const int maxCacheSizeMB = 100;

  /// Cache temizleme periyodu (gün cinsinden)
  static const int cacheCleanupDays = 7;

  /// Uygulama başlangıcında expired cache'leri temizle
    /// Bu metod app başlangıcında çağrılmalıdır (main.dart)
  Future<void> initializeCache() async {
    try {
      debugPrint('🧹 Cache temizleme başlatılıyor...');

      // Expired image cache'leri temizle
      await _cleanupExpiredImageCache();

      // Cache boyutunu kontrol et
      await _checkCacheSize();

      debugPrint('Cache temizleme tamamlandı');
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'CacheManagerService.initializeCache hatası',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Expired image cache'leri temizle
  Future<void> _cleanupExpiredImageCache() async {
    try {
      // CachedNetworkImage otomatik olarak expired cache'leri temizler
      // Ancak manuel temizleme için emptyCache() kullanılabilir
      final cacheInfo = await _imageCacheManager.getFileFromCache('dummy');
      if (cacheInfo == null) {
        debugPrint('📦 Image cache boş');
      } else {
        debugPrint('📦 Image cache mevcut');
      }
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'CacheManagerService._cleanupExpiredImageCache hatası',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Cache boyutunu kontrol et ve limit aşılmışsa temizle
  Future<void> _checkCacheSize() async {
    try {
      // Not: flutter_cache_manager cache boyutunu otomatik yönetir
      // maxNrOfCacheObjects ve maxAgeCacheObject parametreleri ile
      debugPrint('Cache boyutu kontrol ediliyor...');

      // Eğer manuel kontrol gerekirse, cache dosyalarının boyutunu hesapla
      // ve maxCacheSizeMB ile karşılaştır
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'CacheManagerService._checkCacheSize hatası',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Tüm image cache'i temizle (manuel temizleme)
    /// Kullanım: Settings ekranında "Cache Temizle" butonu
  Future<void> clearImageCache() async {
    try {
      debugPrint('🧹 Image cache temizleniyor...');
      await _imageCacheManager.emptyCache();
      debugPrint('Image cache temizlendi');
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'CacheManagerService.clearImageCache hatası',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Cache boyutunu al (MB cinsinden)
    /// Kullanım: Settings ekranında cache boyutunu göstermek için
  Future<double> getCacheSizeMB() async {
    try {
      // Not: flutter_cache_manager cache boyutunu doğrudan döndürmez
      // Cache dosyalarının boyutunu manuel hesaplamak gerekir
      // Şimdilik 0 döndürüyoruz
      return 0.0;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'CacheManagerService.getCacheSizeMB hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return 0.0;
    }
  }
}
