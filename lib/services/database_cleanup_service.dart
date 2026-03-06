import 'package:flutter/foundation.dart';
import '../core/app_globals.dart';

/// Veritabanı temizleme servisi
/// Eski ve gereksiz kayıtları otomatik olarak temizler
class DatabaseCleanupService {
  static final DatabaseCleanupService _instance =
      DatabaseCleanupService._internal();
  factory DatabaseCleanupService() => _instance;
  DatabaseCleanupService._internal();

  /// Eski activity_logs kayıtlarını temizle (90 gün geçmiş)
  Future<int> cleanupOldActivityLogs() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));

      debugPrint(
        '🧹 Eski activity_logs temizleniyor (${cutoffDate.toString().split(' ')[0]} öncesi)...',
      );

      final response = await supabase
          .from('activity_logs')
          .delete()
          .lt('created_at', cutoffDate.toIso8601String());

      final deletedCount = response.count ?? 0;
      debugPrint('Toplam $deletedCount activity_log kaydı temizlendi');
      return deletedCount;
    } catch (e) {
      debugPrint('Activity_logs temizlenirken hata: $e');
      return 0;
    }
  }

  /// Tüm temizleme işlemlerini yap
  Future<Map<String, int>> performFullCleanup() async {
    debugPrint('🧹 Tam veritabanı temizliği başlatılıyor...');

    final results = <String, int>{};

    // Activity logs temizle
    results['activityLogs'] = await cleanupOldActivityLogs();

    debugPrint('Tam veritabanı temizliği tamamlandı');
    debugPrint('Sonuçlar:');
    debugPrint('    - Activity Logs: ${results['activityLogs']} kayıt');

    return results;
  }
}
