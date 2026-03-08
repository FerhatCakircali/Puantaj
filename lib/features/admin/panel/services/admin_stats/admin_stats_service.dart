import 'package:flutter/foundation.dart';
import '../../../../../models/admin_stats.dart';
import 'collectors/user_stats_collector.dart';
import 'collectors/registration_stats_collector.dart';
import 'monitors/database_monitor.dart';
import 'monitors/auth_monitor.dart';
import 'cache/stats_cache_manager.dart';

/// Admin istatistik servisi - koordinatör
///
/// İstatistik toplama, sistem izleme ve cache yönetimini koordine eder.
class AdminStatsService {
  static final AdminStatsService _instance = AdminStatsService._internal();
  factory AdminStatsService() => _instance;
  AdminStatsService._internal();

  final _userStatsCollector = UserStatsCollector();
  final _registrationStatsCollector = RegistrationStatsCollector();
  final _databaseMonitor = DatabaseMonitor();
  final _authMonitor = AuthMonitor();
  final _cacheManager = StatsCacheManager();

  /// İstatistikleri getirir (cache ile)
  Future<AdminStats> getStats({bool forceRefresh = false}) async {
    // Cache kontrolü
    if (!forceRefresh && _cacheManager.isStatsCacheValid()) {
      return _cacheManager.getCachedStats()!;
    }

    try {
      debugPrint('İstatistikler yenileniyor...');

      // Paralel olarak tüm istatistikleri çek
      final futures = await Future.wait([
        _userStatsCollector.getTotalUsers(),
        _userStatsCollector.getActiveUsers(),
        _userStatsCollector.getBlockedUsers(),
        _userStatsCollector.getAdminUsers(),
        _registrationStatsCollector.getTodayRegistrations(),
        _registrationStatsCollector.getWeeklyRegistrations(),
        _registrationStatsCollector.getMonthlyRegistrations(),
      ]);

      final stats = AdminStats(
        totalUsers: futures[0],
        activeUsers: futures[1],
        blockedUsers: futures[2],
        adminUsers: futures[3],
        todayRegistrations: futures[4],
        weeklyRegistrations: futures[5],
        monthlyRegistrations: futures[6],
        lastUpdated: DateTime.now(),
      );

      // Cache'e kaydet
      _cacheManager.cacheStats(stats);

      debugPrint('İstatistikler güncellendi');
      return stats;
    } catch (e) {
      debugPrint('AdminStatsService hata: $e');
      rethrow;
    }
  }

  /// Sistem durumunu kontrol eder (cache ile)
  Future<Map<String, dynamic>> getSystemStatus({
    bool forceRefresh = false,
  }) async {
    // Cache kontrolü
    if (!forceRefresh && _cacheManager.isSystemStatusCacheValid()) {
      return _cacheManager.getCachedSystemStatus()!;
    }

    try {
      debugPrint('Sistem durumu kontrol ediliyor...');

      // Veritabanı ve Auth testleri
      final dbTest = await _databaseMonitor.checkConnection();
      final authTest = await _authMonitor.checkAuth();

      // Genel durum hesapla
      final overallStatus = _calculateOverallStatus(
        dbTest['status'],
        authTest['status'],
      );

      final systemStatus = {
        'database': dbTest,
        'auth': authTest,
        'overall': {
          'status': overallStatus,
          'message': _getOverallMessage(overallStatus),
          'last_check': DateTime.now().toIso8601String(),
        },
      };

      // Cache'e kaydet
      _cacheManager.cacheSystemStatus(systemStatus);

      debugPrint('Sistem durumu güncellendi');
      return systemStatus;
    } catch (e) {
      debugPrint('Sistem durumu kontrol hatası: $e');
      return _getErrorSystemStatus(e.toString());
    }
  }

  /// Genel sistem durumunu hesaplar
  String _calculateOverallStatus(String dbStatus, String authStatus) {
    if (dbStatus == 'error' || authStatus == 'error') {
      return 'error';
    } else if (dbStatus == 'warning' || authStatus == 'warning') {
      return 'warning';
    } else {
      return 'healthy';
    }
  }

  /// Genel durum mesajını getirir
  String _getOverallMessage(String status) {
    switch (status) {
      case 'healthy':
        return 'Tüm sistemler normal çalışıyor';
      case 'warning':
        return 'Bazı sistemlerde uyarı var';
      case 'error':
        return 'Kritik sistem hatası tespit edildi';
      default:
        return 'Sistem durumu bilinmiyor';
    }
  }

  /// Hata durumunda sistem durumu
  Map<String, dynamic> _getErrorSystemStatus(String error) {
    return {
      'database': {
        'status': 'error',
        'message': 'Veritabanı durumu kontrol edilemiyor: $error',
        'last_check': DateTime.now().toIso8601String(),
      },
      'auth': {
        'status': 'unknown',
        'message': 'Kimlik doğrulama durumu bilinmiyor',
        'last_check': DateTime.now().toIso8601String(),
      },
      'overall': {
        'status': 'error',
        'message': 'Sistem durumu kontrol edilemiyor',
        'last_check': DateTime.now().toIso8601String(),
      },
    };
  }

  /// Tüm cache'leri temizler
  void clearCache() => _cacheManager.clearAll();

  /// Sadece istatistik cache'ini temizler
  void clearStatsCache() => _cacheManager.clearStats();

  /// Sadece sistem durumu cache'ini temizler
  void clearSystemStatusCache() => _cacheManager.clearSystemStatus();

  /// Cache durumunu kontrol eder
  Map<String, dynamic> getCacheStatus() => _cacheManager.getStatus();
}
