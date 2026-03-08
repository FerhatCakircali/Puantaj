import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/error_handling/error_handler_mixin.dart';

/// Veritabanı temizleme servisi
/// Eski ve gereksiz kayıtları otomatik olarak temizler
class DatabaseCleanupService with ErrorHandlerMixin {
  final SupabaseClient _supabase;

  DatabaseCleanupService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// Eski activity_logs kayıtlarını temizle (90 gün geçmiş)
  Future<int> cleanupOldActivityLogs() async {
    return handleError(
      () async {
        final cutoffDate = DateTime.now().subtract(const Duration(days: 90));

        debugPrint(
          '🧹 Eski activity_logs temizleniyor (${cutoffDate.toString().split(' ')[0]} öncesi)...',
        );

        final response = await _supabase
            .from('activity_logs')
            .delete()
            .lt('created_at', cutoffDate.toIso8601String());

        final deletedCount = response.count ?? 0;
        debugPrint('Toplam $deletedCount activity_log kaydı temizlendi');
        return deletedCount;
      },
      0,
      context: 'DatabaseCleanupService.cleanupOldActivityLogs',
    );
  }

  /// Tüm temizleme işlemlerini yap
  Future<Map<String, int>> performFullCleanup() async {
    return handleError(
      () async {
        debugPrint('🧹 Tam veritabanı temizliği başlatılıyor...');

        final results = <String, int>{};

        // Activity logs temizle
        results['activityLogs'] = await cleanupOldActivityLogs();

        debugPrint('Tam veritabanı temizliği tamamlandı');
        debugPrint('Sonuçlar:');
        debugPrint('    - Activity Logs: ${results['activityLogs']} kayıt');

        return results;
      },
      {},
      context: 'DatabaseCleanupService.performFullCleanup',
    );
  }
}
