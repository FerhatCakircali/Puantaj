import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/dashboard_constants.dart';

/// Dashboard ödeme verileri repository'si
///
/// Ödeme kayıtları ile ilgili veritabanı işlemlerini yönetir.
class DashboardPaymentRepository {
  final _supabase = Supabase.instance.client;

  /// Son 3 ödemeyi getirir
  Future<List<Map<String, dynamic>>> getRecentPayments(
    int workerId,
    int userId,
  ) async {
    try {
      final response = await _supabase
          .from(DashboardConstants.paymentsTable)
          .select('payment_date, amount, full_days, half_days')
          .eq('worker_id', workerId)
          .eq('user_id', userId)
          .order('payment_date', ascending: false)
          .limit(DashboardConstants.recentPaymentsLimit);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      return [];
    }
  }

  /// Aylık ortalama kazancı hesaplar
  Future<double> getMonthlyAverage(int workerId, int userId) async {
    try {
      final response = await _supabase
          .from(DashboardConstants.paymentsTable)
          .select('amount, payment_date')
          .eq('worker_id', workerId)
          .eq('user_id', userId);

      if ((response as List).isEmpty) return 0.0;

      final monthlyTotals = <String, double>{};
      for (var payment in response) {
        final date = DateTime.parse(payment['payment_date']);
        final monthKey = '${date.year}-${date.month}';
        monthlyTotals[monthKey] =
            (monthlyTotals[monthKey] ?? 0) +
            (payment['amount'] as num).toDouble();
      }

      final total = monthlyTotals.values.reduce((a, b) => a + b);
      return total / monthlyTotals.length;
    } catch (e) {
      return 0.0;
    }
  }

  /// Son ödeme tarihini getirir
  Future<DateTime?> getLastPayment(int workerId, int userId) async {
    try {
      final response = await _supabase
          .from(DashboardConstants.paymentsTable)
          .select('payment_date')
          .eq('worker_id', workerId)
          .eq('user_id', userId)
          .order('payment_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return DateTime.parse(response['payment_date']);
    } catch (e) {
      return null;
    }
  }
}
