import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance.dart';
import 'auth_service.dart';

class AttendanceService {
  final AuthService _authService = AuthService();

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  SupabaseClient get supabase => Supabase.instance.client;

  Future<List<Attendance>> getAttendanceByDate(DateTime date) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return [];

      final formattedDate = _formatDate(date);

      final results = await supabase
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .like('date', '$formattedDate%');

      return results.map<Attendance>((map) => Attendance.fromMap(map)).toList();
    } catch (e) {
      debugPrint('getAttendanceByDate hata: $e');
      return [];
    }
  }

  Future<List<Attendance>> getAttendanceBetween(
    DateTime startDate,
    DateTime endDate, {
    int? workerId,
  }) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return [];

      final formattedStartDate = _formatDate(startDate);
      final formattedEndDate = _formatDate(endDate);

      var query = supabase
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .gte('date', formattedStartDate)
          .lte('date', formattedEndDate);

      if (workerId != null) {
        query = query.eq('worker_id', workerId);
      }

      final results = await query;

      return results.map<Attendance>((map) => Attendance.fromMap(map)).toList();
    } catch (e) {
      debugPrint('getAttendanceBetween hata: $e');
      return [];
    }
  }

  Future<void> markAttendance({
    required int workerId,
    required DateTime date,
    required AttendanceStatus status,
  }) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return;

      final formattedDate = _formatDate(date);

      await supabase.from('attendance').insert({
        'worker_id': workerId,
        'user_id': userId,
        'date': formattedDate,
        'status': status.name,
      });
    } catch (e) {
      debugPrint('markAttendance hata: $e');
    }
  }
}
