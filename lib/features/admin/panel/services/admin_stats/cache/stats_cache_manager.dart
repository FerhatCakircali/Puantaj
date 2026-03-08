import 'package:flutter/foundation.dart';
import '../../../../../../models/admin_stats.dart';

/// İstatistik cache yönetimi sınıfı
class StatsCacheManager {
  AdminStats? _cachedStats;
  DateTime? _lastCacheTime;
  Map<String, dynamic>? _cachedSystemStatus;
  DateTime? _lastSystemStatusCacheTime;

  static const Duration _cacheTimeout = Duration(minutes: 5);
  static const Duration _systemStatusCacheTimeout = Duration(minutes: 2);

  /// İstatistik cache'ini kontrol eder
  bool isStatsCacheValid() {
    return _cachedStats != null &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < _cacheTimeout;
  }

  /// Sistem durumu cache'ini kontrol eder
  bool isSystemStatusCacheValid() {
    return _cachedSystemStatus != null &&
        _lastSystemStatusCacheTime != null &&
        DateTime.now().difference(_lastSystemStatusCacheTime!) <
            _systemStatusCacheTimeout;
  }

  /// İstatistikleri cache'e kaydeder
  void cacheStats(AdminStats stats) {
    _cachedStats = stats;
    _lastCacheTime = DateTime.now();
    debugPrint('İstatistikler cache\'e kaydedildi');
  }

  /// Sistem durumunu cache'e kaydeder
  void cacheSystemStatus(Map<String, dynamic> status) {
    _cachedSystemStatus = status;
    _lastSystemStatusCacheTime = DateTime.now();
    debugPrint('Sistem durumu cache\'e kaydedildi');
  }

  /// Cache'lenmiş istatistikleri döndürür
  AdminStats? getCachedStats() => _cachedStats;

  /// Cache'lenmiş sistem durumunu döndürür
  Map<String, dynamic>? getCachedSystemStatus() => _cachedSystemStatus;

  /// Tüm cache'leri temizler
  void clearAll() {
    _cachedStats = null;
    _lastCacheTime = null;
    _cachedSystemStatus = null;
    _lastSystemStatusCacheTime = null;
    debugPrint('Tüm cache temizlendi');
  }

  /// Sadece istatistik cache'ini temizler
  void clearStats() {
    _cachedStats = null;
    _lastCacheTime = null;
    debugPrint('İstatistik cache temizlendi');
  }

  /// Sadece sistem durumu cache'ini temizler
  void clearSystemStatus() {
    _cachedSystemStatus = null;
    _lastSystemStatusCacheTime = null;
    debugPrint('Sistem durumu cache temizlendi');
  }

  /// Cache durumunu döndürür
  Map<String, dynamic> getStatus() {
    return {
      'stats_cached': _cachedStats != null,
      'stats_cache_age_minutes': _lastCacheTime != null
          ? DateTime.now().difference(_lastCacheTime!).inMinutes
          : null,
      'system_status_cached': _cachedSystemStatus != null,
      'system_status_cache_age_minutes': _lastSystemStatusCacheTime != null
          ? DateTime.now().difference(_lastSystemStatusCacheTime!).inMinutes
          : null,
    };
  }
}
