import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/activity_log.dart';
import '../../../../core/app_globals.dart';

class ActivityLogService {
  static final ActivityLogService _instance = ActivityLogService._internal();
  factory ActivityLogService() => _instance;
  ActivityLogService._internal();

  /// Aktivite logu kaydet
  Future<void> logActivity({
    required int adminId,
    required String adminUsername,
    required String actionType,
    int? targetUserId,
    String? targetUsername,
    Map<String, dynamic>? details,
  }) async {
    try {
      await supabase.from('activity_logs').insert({
        'admin_id': adminId,
        'admin_username': adminUsername,
        'action_type': actionType,
        'target_user_id': targetUserId,
        'target_username': targetUsername,
        'details': details,
        // created_at otomatik olarak Supabase tarafından UTC'de eklenir
      });

      debugPrint('📝 Aktivite logu kaydedildi: $actionType');
    } catch (e) {
      debugPrint('❌ Aktivite logu kaydetme hatası: $e');
    }
  }

  /// Son aktiviteleri getir (dashboard için)
  Future<List<ActivityLog>> getRecentActivities({int limit = 10}) async {
    try {
      final response = await supabase
          .from('activity_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ActivityLog.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Son aktiviteler getirme hatası: $e');
      return [];
    }
  }

  /// Bugünkü aktivite sayısı
  Future<int> getTodayActivityCount() async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final response = await supabase
          .from('activity_logs')
          .select('id')
          .gte('created_at', todayStart.toIso8601String())
          .lt('created_at', todayEnd.toIso8601String())
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      debugPrint('❌ Bugünkü aktivite sayısı getirme hatası: $e');
      return 0;
    }
  }

  /// Bu haftaki aktivite sayısı
  Future<int> getWeeklyActivityCount() async {
    try {
      final today = DateTime.now();
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekStartDay = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day,
      );

      final response = await supabase
          .from('activity_logs')
          .select('id')
          .gte('created_at', weekStartDay.toIso8601String())
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      debugPrint('❌ Haftalık aktivite sayısı getirme hatası: $e');
      return 0;
    }
  }
}
