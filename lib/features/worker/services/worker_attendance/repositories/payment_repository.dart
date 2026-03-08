import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/date_formatter.dart';

/// Ödeme verilerini yöneten repository
class PaymentRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Toplam kazancı getirir
  Future<double> getTotalPayments(int workerId) async {
    try {
      final response = await _supabase.rpc(
        'get_worker_total_payments',
        params: {'worker_id_param': workerId},
      );

      if (response == null) return 0.0;

      return double.tryParse(response.toString()) ?? 0.0;
    } catch (e) {
      debugPrint('getTotalPayments hata: $e');
      return 0.0;
    }
  }

  /// Ödeme geçmişini getirir
  Future<List<Map<String, dynamic>>> getHistory({
    required int workerId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('*')
          .eq('worker_id', workerId)
          .gte('payment_date', startDate)
          .lte('payment_date', endDate)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getHistory hata: $e');
      return [];
    }
  }

  /// Ödeme detaylarını getirir
  Future<Map<String, dynamic>?> getDetails(int paymentId) async {
    try {
      final payment = await _supabase
          .from('payments')
          .select('*')
          .eq('id', paymentId)
          .maybeSingle();

      if (payment == null) return null;

      final workerId = payment['worker_id'] as int;
      final paymentDate = DateTime.parse(payment['payment_date']);

      final startDate = paymentDate.subtract(const Duration(days: 30));

      final attendanceRecords = await _supabase
          .from('attendance')
          .select('date, status')
          .eq('worker_id', workerId)
          .gte('date', DateFormatter.format(startDate))
          .lte('date', DateFormatter.format(paymentDate))
          .order('date', ascending: true);

      return {'payment': payment, 'attendance_records': attendanceRecords};
    } catch (e) {
      debugPrint('getDetails hata: $e');
      return null;
    }
  }

  /// Belirli dönemdeki toplam ödeme tutarını hesaplar
  Future<double> getTotalAmountForPeriod({
    required int workerId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('amount')
          .eq('worker_id', workerId)
          .gte('payment_date', startDate)
          .lte('payment_date', endDate);

      double totalAmount = 0.0;
      for (final payment in response) {
        totalAmount += (payment['amount'] as num).toDouble();
      }

      return totalAmount;
    } catch (e) {
      debugPrint('getTotalAmountForPeriod hata: $e');
      return 0.0;
    }
  }
}
