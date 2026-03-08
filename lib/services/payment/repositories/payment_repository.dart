import 'package:flutter/foundation.dart';
import '../../../models/payment.dart';
import '../../../models/payment_summary.dart';
import '../../../core/repositories/base_supabase_repository.dart';
import '../../../utils/date_formatter.dart';
import '../constants/payment_constants.dart';

/// Ödeme verilerini veritabanından yöneten repository sınıfı
class PaymentRepository extends BaseSupabaseRepository {
  PaymentRepository(super.supabase);

  /// Yeni ödeme kaydı ekler
  ///
  /// [paymentData] Ödeme verisi (map formatında)
  /// Returns: Eklenen ödeme ID'si ve tarihi
  Future<Map<String, dynamic>> insertPayment(
    Map<String, dynamic> paymentData,
  ) async {
    return executeQueryWithThrow(() async {
      final response = await supabase
          .from(PaymentConstants.paymentsTable)
          .insert(paymentData)
          .select('id, payment_date')
          .single();

      return response;
    }, context: 'PaymentRepository.insertPayment');
  }

  /// Çalışana ait ödemeleri getirir
  ///
  /// [workerId] Çalışan ID'si
  /// [userId] Kullanıcı ID'si
  /// Returns: Ödeme listesi
  Future<List<Payment>> getPaymentsByWorker(int workerId, int userId) async {
    return executeQuery(
      () async {
        final maps = await supabase
            .from(PaymentConstants.paymentsTable)
            .select()
            .eq(PaymentConstants.workerIdColumn, workerId)
            .eq(PaymentConstants.userIdColumn, userId)
            .order(PaymentConstants.paymentDateColumn, ascending: false);

        return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
      },
      [],
      context: 'PaymentRepository.getPaymentsByWorker',
    );
  }

  /// Ödeme kaydını günceller (RPC)
  ///
  /// [paymentId] Ödeme ID'si
  /// [fullDays] Tam gün sayısı
  /// [halfDays] Yarım gün sayısı
  /// [amount] Ödeme tutarı
  /// Returns: İşlem başarılı ise true
  Future<bool> updatePayment({
    required int paymentId,
    required int fullDays,
    required int halfDays,
    required double amount,
  }) async {
    return executeQueryWithThrow(() async {
      debugPrint('Ödeme güncelleniyor: ID=$paymentId');

      final result = await supabase.rpc(
        PaymentConstants.rpcUpdatePayment,
        params: {
          'payment_id_param': paymentId,
          'full_days_param': fullDays,
          'half_days_param': halfDays,
          'amount_param': amount,
        },
      );

      return result == true;
    }, context: 'PaymentRepository.updatePayment');
  }

  /// Ödeme kaydını siler (RPC)
  ///
  /// [paymentId] Ödeme ID'si
  /// Returns: İşlem başarılı ise true
  Future<bool> deletePayment(int paymentId) async {
    return executeQueryWithThrow(() async {
      debugPrint('Ödeme siliniyor: ID=$paymentId');

      final result = await supabase.rpc(
        PaymentConstants.rpcDeletePayment,
        params: {'payment_id_param': paymentId},
      );

      return result == true;
    }, context: 'PaymentRepository.deletePayment');
  }

  /// Kullanıcının ödeme geçmişini getirir
  ///
  /// [userId] Kullanıcı ID'si
  /// [startDate] Başlangıç tarihi
  /// [endDate] Bitiş tarihi
  /// Returns: Ödeme ve avans listesi
  Future<List<Map<String, dynamic>>> getUserPaymentHistory({
    required int userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return executeQuery(
      () async {
        debugPrint('Ödeme geçmişi getiriliyor: $startDate - $endDate');

        final paymentsResults = await supabase
            .from(PaymentConstants.paymentsTable)
            .select('*, workers!inner(full_name)')
            .eq(PaymentConstants.userIdColumn, userId)
            .gte(
              PaymentConstants.paymentDateColumn,
              DateFormatter.toIso8601Date(startDate),
            )
            .lte(
              PaymentConstants.paymentDateColumn,
              DateFormatter.toIso8601Date(endDate),
            );

        final advancesResults = await supabase
            .from(PaymentConstants.advancesTable)
            .select('*, workers!inner(full_name)')
            .eq(PaymentConstants.userIdColumn, userId)
            .gte(
              PaymentConstants.advanceDateColumn,
              DateFormatter.toIso8601Date(startDate),
            )
            .lte(
              PaymentConstants.advanceDateColumn,
              DateFormatter.toIso8601Date(endDate),
            );

        final advancesAsPayments = advancesResults.map((advance) {
          return {
            'id': advance['id'],
            'user_id': advance['user_id'],
            'worker_id': advance['worker_id'],
            'amount': advance['amount'],
            'payment_date': advance['advance_date'],
            'created_at': advance['created_at'],
            'updated_at': advance['updated_at'],
            'workers': advance['workers'],
            'full_days': 0,
            'half_days': 0,
            'is_advance': true,
            'description': advance['description'],
          };
        }).toList();

        final paymentsWithFlag = paymentsResults.map((payment) {
          return {...payment, 'is_advance': false};
        }).toList();

        final combined = [...paymentsWithFlag, ...advancesAsPayments];

        combined.sort((a, b) {
          final dateA = DateTime.parse(a['payment_date'] as String);
          final dateB = DateTime.parse(b['payment_date'] as String);
          return dateB.compareTo(dateA);
        });

        debugPrint(
          'Ödeme geçmişi getirildi: ${combined.length} kayıt (${paymentsResults.length} ödeme, ${advancesResults.length} avans)',
        );

        return combined;
      },
      [],
      context: 'PaymentRepository.getUserPaymentHistory',
    );
  }

  /// Ödeme özet bilgilerini getirir (RPC)
  ///
  /// [userId] Kullanıcı ID'si
  /// [startDate] Başlangıç tarihi
  /// [endDate] Bitiş tarihi
  /// Returns: Ödeme özeti veya null
  Future<PaymentSummary?> getPaymentSummary({
    required int userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return executeQuery(
      () async {
        debugPrint('Ödeme özeti getiriliyor: $startDate - $endDate');

        final List<dynamic> data = await supabase.rpc(
          PaymentConstants.rpcGetPaymentSummary,
          params: {
            'p_user_id': userId,
            'p_start_date': DateFormatter.toIso8601Date(startDate),
            'p_end_date': DateFormatter.toIso8601Date(endDate),
          },
        );

        if (data.isEmpty) {
          debugPrint('Ödeme özeti bulunamadı');
          return null;
        }

        final summary = PaymentSummary.fromMap(
          data.first as Map<String, dynamic>,
        );
        debugPrint('Ödeme özeti getirildi: ${summary.totalPayments} ödeme');

        return summary;
      },
      null,
      context: 'PaymentRepository.getPaymentSummary',
    );
  }
}
