import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/dashboard_constants.dart';

/// Dashboard bildirim verileri repository'si
///
/// Bildirim kayıtları ile ilgili veritabanı işlemlerini yönetir.
class DashboardNotificationRepository {
  final _supabase = Supabase.instance.client;

  /// Okunmamış bildirim sayısını getirir
  Future<int> getUnreadNotificationsCount(int workerId) async {
    try {
      final response = await _supabase
          .from(DashboardConstants.notificationsTable)
          .select('id')
          .eq('recipient_id', workerId)
          .eq('recipient_type', DashboardConstants.recipientTypeWorker)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}
