import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Çalışan verilerini yöneten repository
class WorkerRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Çalışanın yönetici ID'sini ve adını getirir
  Future<Map<String, dynamic>?> getWorkerInfo(int workerId) async {
    try {
      final response = await _supabase
          .from('workers')
          .select('user_id, full_name')
          .eq('id', workerId)
          .single();

      return {
        'managerId': response['user_id'] as int,
        'workerName': response['full_name'] as String,
      };
    } catch (e) {
      debugPrint('getWorkerInfo hata: $e');
      return null;
    }
  }

  /// Çalışanın başlangıç tarihini getirir
  Future<DateTime?> getWorkerStartDate(int workerId) async {
    try {
      final response = await _supabase
          .from('workers')
          .select('start_date')
          .eq('id', workerId)
          .maybeSingle();

      if (response != null && response['start_date'] != null) {
        return DateTime.parse(response['start_date']);
      }
      return null;
    } catch (e) {
      debugPrint('getWorkerStartDate hata: $e');
      return null;
    }
  }
}
