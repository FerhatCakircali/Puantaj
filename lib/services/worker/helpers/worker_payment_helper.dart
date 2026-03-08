import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/error_logger.dart';
import '../constants/worker_constants.dart';

/// Çalışan ödeme kayıtlarını yöneten helper sınıfı
class WorkerPaymentHelper {
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Yetim kalmış ödemeleri siler
  ///
  /// paid_days tablosunda referansı olmayan payment kayıtlarını temizler.
  ///
  /// [userId] Kullanıcı ID'si
  /// [workerId] Çalışan ID'si
  Future<void> deleteOrphanedPayments(int userId, int workerId) async {
    try {
      final payments = await _supabase
          .from(WorkerConstants.paymentsTable)
          .select('id')
          .eq(WorkerConstants.userIdColumn, userId)
          .eq(WorkerConstants.workerIdColumn, workerId);

      for (final payment in payments) {
        final paymentId = payment['id'] as int;

        final paidDays = await _supabase
            .from(WorkerConstants.paidDaysTable)
            .select()
            .eq(WorkerConstants.paymentIdColumn, paymentId);

        if (paidDays.isEmpty) {
          await _supabase
              .from(WorkerConstants.paymentsTable)
              .delete()
              .eq('id', paymentId);

          debugPrint('Yetim ödeme silindi: $paymentId');
        }
      }
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerPaymentHelper.deleteOrphanedPayments hatası',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Kalan ödemelerin gün sayılarını günceller
  ///
  /// paid_days tablosundaki kayıtlara göre payment'ların full_days ve half_days değerlerini günceller.
  ///
  /// [userId] Kullanıcı ID'si
  /// [workerId] Çalışan ID'si
  Future<void> updateRemainingPayments(int userId, int workerId) async {
    try {
      final payments = await _supabase
          .from(WorkerConstants.paymentsTable)
          .select('id')
          .eq(WorkerConstants.userIdColumn, userId)
          .eq(WorkerConstants.workerIdColumn, workerId);

      for (final payment in payments) {
        final paymentId = payment['id'] as int;

        final fullDaysResult = await _supabase
            .from(WorkerConstants.paidDaysTable)
            .select()
            .eq(WorkerConstants.paymentIdColumn, paymentId)
            .eq(WorkerConstants.statusColumn, WorkerConstants.statusFullDay);

        final fullDays = fullDaysResult.length;

        final halfDaysResult = await _supabase
            .from(WorkerConstants.paidDaysTable)
            .select()
            .eq(WorkerConstants.paymentIdColumn, paymentId)
            .eq(WorkerConstants.statusColumn, WorkerConstants.statusHalfDay);

        final halfDays = halfDaysResult.length;

        await _supabase
            .from(WorkerConstants.paymentsTable)
            .update({'full_days': fullDays, 'half_days': halfDays})
            .eq('id', paymentId);
      }
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerPaymentHelper.updateRemainingPayments hatası',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
