import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/app_globals.dart';

/// Kayıt istatistiklerini toplayan sınıf
class RegistrationStatsCollector {
  /// Bugün kayıt olanlar
  Future<int> getTodayRegistrations() async {
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
  Future<int> getWeeklyRegistrations() async {
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
  Future<int> getMonthlyRegistrations() async {
    final today = DateTime.now();
    final monthStart = DateTime(today.year, today.month, 1);

    final response = await supabase
        .from('users')
        .select('id')
        .gte('created_at', monthStart.toIso8601String())
        .count(CountOption.exact);
    return response.count;
  }
}
