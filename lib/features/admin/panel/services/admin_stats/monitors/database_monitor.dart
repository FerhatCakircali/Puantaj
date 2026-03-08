import 'package:flutter/foundation.dart';
import '../../../../../../core/app_globals.dart';

/// Veritabanı durumunu izleyen sınıf
class DatabaseMonitor {
  /// Veritabanı bağlantısını test eder
  Future<Map<String, dynamic>> checkConnection() async {
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
      debugPrint('Veritabanı bağlantı hatası: $e');
      return {
        'status': 'error',
        'message': 'Veritabanı bağlantı hatası: $e',
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }
}
