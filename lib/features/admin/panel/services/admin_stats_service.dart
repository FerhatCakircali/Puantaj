import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/admin_stats.dart';
import '../../../../core/app_globals.dart';

class AdminStatsService {
  static final AdminStatsService _instance = AdminStatsService._internal();
  factory AdminStatsService() => _instance;
  AdminStatsService._internal();

  AdminStats? _cachedStats;
  DateTime? _lastCacheTime;
  Map<String, dynamic>? _cachedSystemStatus;
  DateTime? _lastSystemStatusCacheTime;

  static const Duration _cacheTimeout = Duration(minutes: 5);
  static const Duration _systemStatusCacheTimeout = Duration(minutes: 2);

  /// İstatistikleri getir (cache ile)
  Future<AdminStats> getStats({bool forceRefresh = false}) async {
    // Cache kontrolü
    if (!forceRefresh &&
        _cachedStats != null &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < _cacheTimeout) {
      return _cachedStats!;
    }

    try {
      debugPrint('📊 İstatistikler yenileniyor...');

      // Paralel olarak tüm istatistikleri çek
      final futures = await Future.wait([
        _getTotalUsers(),
        _getActiveUsers(),
        _getBlockedUsers(),
        _getAdminUsers(),
        _getTodayRegistrations(),
        _getWeeklyRegistrations(),
        _getMonthlyRegistrations(),
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
      _cachedStats = stats;
      _lastCacheTime = DateTime.now();

      debugPrint('✅ İstatistikler güncellendi');
      return stats;
    } catch (e) {
      debugPrint('❌ AdminStatsService hata: $e');
      rethrow;
    }
  }

  /// Toplam kullanıcı sayısı
  Future<int> _getTotalUsers() async {
    final response = await supabase
        .from('users')
        .select('id')
        .count(CountOption.exact);
    return response.count;
  }

  /// Aktif kullanıcılar (bloklu olmayanlar)
  Future<int> _getActiveUsers() async {
    final response = await supabase
        .from('users')
        .select('id')
        .eq('is_blocked', false)
        .count(CountOption.exact);
    return response.count;
  }

  /// Bloklu kullanıcılar
  Future<int> _getBlockedUsers() async {
    final response = await supabase
        .from('users')
        .select('id')
        .eq('is_blocked', true)
        .count(CountOption.exact);
    return response.count;
  }

  /// Admin kullanıcılar
  Future<int> _getAdminUsers() async {
    final response = await supabase
        .from('users')
        .select('id')
        .eq('is_admin', 1)
        .count(CountOption.exact);
    return response.count;
  }

  /// Bugün kayıt olanlar
  Future<int> _getTodayRegistrations() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final response = await supabase
        .from('users')
        .select('id')
        .gte('created_at', todayStart.toIso8601String())
        .lt('created_at', todayEnd.toIso8601String())
        .count(CountOption.exact);
    return response.count;
  }

  /// Bu hafta kayıt olanlar
  Future<int> _getWeeklyRegistrations() async {
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekStartDay = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    final response = await supabase
        .from('users')
        .select('id')
        .gte('created_at', weekStartDay.toIso8601String())
        .count(CountOption.exact);
    return response.count;
  }

  /// Bu ay kayıt olanlar
  Future<int> _getMonthlyRegistrations() async {
    final today = DateTime.now();
    final monthStart = DateTime(today.year, today.month, 1);

    final response = await supabase
        .from('users')
        .select('id')
        .gte('created_at', monthStart.toIso8601String())
        .count(CountOption.exact);
    return response.count;
  }

  /// Sistem durumu kontrol et (cache ile)
  Future<Map<String, dynamic>> getSystemStatus({
    bool forceRefresh = false,
  }) async {
    // Cache kontrolü
    if (!forceRefresh &&
        _cachedSystemStatus != null &&
        _lastSystemStatusCacheTime != null &&
        DateTime.now().difference(_lastSystemStatusCacheTime!) <
            _systemStatusCacheTimeout) {
      return _cachedSystemStatus!;
    }

    try {
      debugPrint('🔍 Sistem durumu kontrol ediliyor...');

      // Veritabanı bağlantı testi
      final dbTest = await _testDatabaseConnection();

      // Auth sistemi testi
      final authTest = await _testAuthSystem();

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
      _cachedSystemStatus = systemStatus;
      _lastSystemStatusCacheTime = DateTime.now();

      debugPrint('✅ Sistem durumu güncellendi');
      return systemStatus;
    } catch (e) {
      debugPrint('❌ Sistem durumu kontrol hatası: $e');
      return _getErrorSystemStatus(e.toString());
    }
  }

  /// Veritabanı bağlantısını test et
  Future<Map<String, dynamic>> _testDatabaseConnection() async {
    try {
      final startTime = DateTime.now();

      // Basit bir sorgu ile bağlantıyı test et
      await supabase.from('users').select('id').limit(1);

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      String status;
      String message;

      if (responseTime < 500) {
        status = 'healthy';
        message = 'Veritabanı bağlantısı mükemmel (${responseTime}ms)';
      } else if (responseTime < 2000) {
        status = 'warning';
        message = 'Veritabanı bağlantısı yavaş (${responseTime}ms)';
      } else {
        status = 'error';
        message = 'Veritabanı bağlantısı çok yavaş (${responseTime}ms)';
      }

      return {
        'status': status,
        'message': message,
        'response_time_ms': responseTime,
        'last_check': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Veritabanı bağlantı hatası: $e',
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Auth sistemini test et
  Future<Map<String, dynamic>> _testAuthSystem() async {
    try {
      // Mevcut kullanıcı bilgilerini kontrol et
      final user = supabase.auth.currentUser;

      if (user != null) {
        return {
          'status': 'healthy',
          'message': 'Kimlik doğrulama sistemi normal çalışıyor',
          'user_id': user.id,
          'last_check': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'status': 'warning',
          'message': 'Kullanıcı oturumu bulunamadı',
          'last_check': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Kimlik doğrulama sistemi hatası: $e',
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Genel sistem durumunu hesapla
  String _calculateOverallStatus(String dbStatus, String authStatus) {
    if (dbStatus == 'error' || authStatus == 'error') {
      return 'error';
    } else if (dbStatus == 'warning' || authStatus == 'warning') {
      return 'warning';
    } else {
      return 'healthy';
    }
  }

  /// Genel durum mesajını getir
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

  /// Tüm cache'leri temizle
  void clearCache() {
    _cachedStats = null;
    _lastCacheTime = null;
    _cachedSystemStatus = null;
    _lastSystemStatusCacheTime = null;
    debugPrint('🗑️ Tüm cache temizlendi');
  }

  /// Sadece istatistik cache'ini temizle
  void clearStatsCache() {
    _cachedStats = null;
    _lastCacheTime = null;
    debugPrint('🗑️ İstatistik cache temizlendi');
  }

  /// Sadece sistem durumu cache'ini temizle
  void clearSystemStatusCache() {
    _cachedSystemStatus = null;
    _lastSystemStatusCacheTime = null;
    debugPrint('🗑️ Sistem durumu cache temizlendi');
  }

  /// Cache durumunu kontrol et
  Map<String, dynamic> getCacheStatus() {
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
