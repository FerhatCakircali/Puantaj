import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/app_globals.dart';

/// Kullanıcı istatistiklerini toplayan sınıf
class UserStatsCollector {
  /// Toplam kullanıcı sayısı
  Future<int> getTotalUsers() async {
    final response = await supabase
        .from('users')
        .select('id')
        .count(CountOption.exact);
    return response.count;
  }

  /// Aktif kullanıcılar (bloklu olmayanlar)
  Future<int> getActiveUsers() async {
    final response = await supabase
        .from('users')
        .select('id')
        .eq('is_blocked', false)
        .count(CountOption.exact);
    return response.count;
  }

  /// Bloklu kullanıcılar
  Future<int> getBlockedUsers() async {
    final response = await supabase
        .from('users')
        .select('id')
        .eq('is_blocked', true)
        .count(CountOption.exact);
    return response.count;
  }

  /// Admin kullanıcılar
  Future<int> getAdminUsers() async {
    final response = await supabase
        .from('users')
        .select('id')
        .eq('is_admin', 1)
        .count(CountOption.exact);
    return response.count;
  }
}
