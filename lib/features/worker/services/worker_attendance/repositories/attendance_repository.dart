import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../models/attendance.dart';
import '../utils/date_formatter.dart';

/// Yevmiye verilerini yöneten repository
class AttendanceRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Bugün için yevmiye durumunu kontrol eder
  Future<Map<String, dynamic>?> checkTodayStatus(int workerId) async {
    try {
      final today = DateFormatter.today();

      final response = await _supabase.rpc(
        'check_worker_today_attendance_status',
        params: {'worker_id_param': workerId, 'check_date': today},
      );

      if (response == null || response.isEmpty) return null;

      return response[0] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('checkTodayStatus hata: $e');
      return null;
    }
  }

  /// Yevmiye talebi gönderir
  Future<bool> submitRequest({
    required int workerId,
    required int managerId,
    required String date,
    required AttendanceStatus status,
  }) async {
    try {
      // Reddedilen talep varsa sil
      await _deleteRejectedRequest(workerId, date);

      // Yeni talep oluştur
      final response = await _supabase
          .from('attendance_requests')
          .insert({
            'worker_id': workerId,
            'user_id': managerId,
            'date': date,
            'status': status.name,
          })
          .select()
          .single();

      final requestId = response['id'] as int;

      debugPrint('Yeni yevmiye talebi gönderildi (ID: $requestId)');
      debugPrint('Database trigger notifications tablosuna kayıt ekleyecek');
      debugPrint('FCM ile bildirim gönderilecek');

      return true;
    } catch (e) {
      debugPrint('submitRequest hata: $e');
      return false;
    }
  }

  /// Reddedilen talebi siler
  Future<void> _deleteRejectedRequest(int workerId, String date) async {
    try {
      final existingRequest = await _supabase
          .from('attendance_requests')
          .select('id, request_status')
          .eq('worker_id', workerId)
          .eq('date', date)
          .maybeSingle();

      if (existingRequest != null &&
          existingRequest['request_status'] == 'rejected') {
        await _supabase
            .from('attendance_requests')
            .delete()
            .eq('id', existingRequest['id']);

        debugPrint('Reddedilen talep silindi');
      }
    } catch (e) {
      debugPrint('_deleteRejectedRequest hata: $e');
    }
  }

  /// Geçmiş yevmiye kayıtlarını getirir
  Future<List<Map<String, dynamic>>> getHistory({
    required int workerId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_worker_attendance_history',
        params: {
          'worker_id_param': workerId,
          'start_date': startDate,
          'end_date': endDate,
        },
      );

      if (response == null) return [];

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getHistory hata: $e');
      return [];
    }
  }

  /// Aylık istatistikleri getirir
  Future<Map<String, dynamic>?> getMonthlyStats({
    required int workerId,
    required String monthStart,
    required String monthEnd,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_worker_monthly_stats',
        params: {
          'worker_id_param': workerId,
          'month_start': monthStart,
          'month_end': monthEnd,
        },
      );

      if (response == null || response.isEmpty) return null;

      return response[0] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getMonthlyStats hata: $e');
      return null;
    }
  }

  /// Ay içindeki yevmiye kayıtlarını getirir
  Future<List<Map<String, dynamic>>> getMonthlyRecords({
    required int workerId,
    required String monthStart,
    required String monthEnd,
  }) async {
    try {
      final response = await _supabase
          .from('attendance')
          .select('date, status')
          .eq('worker_id', workerId)
          .gte('date', monthStart)
          .lte('date', monthEnd)
          .order('date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getMonthlyRecords hata: $e');
      return [];
    }
  }

  /// Reddedilen talebi siler (public)
  Future<bool> deleteRejectedRequest({
    required int workerId,
    required String date,
  }) async {
    try {
      await _supabase
          .from('attendance_requests')
          .delete()
          .eq('worker_id', workerId)
          .eq('date', date)
          .eq('request_status', 'rejected');

      debugPrint('Reddedilen talep silindi');
      return true;
    } catch (e) {
      debugPrint('deleteRejectedRequest hata: $e');
      return false;
    }
  }
}
