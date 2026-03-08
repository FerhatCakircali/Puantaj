import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/error_logger.dart';
import '../../../utils/date_formatter.dart';
import '../../../core/constants/database_constants.dart';

/// Çalışan kayıtlarını temizleme işlemlerini yöneten helper
class EmployeeCleanupHelper {
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Tüm ilişkili kayıtları siler (cascading delete)
  Future<bool> deleteAllRelatedRecords(int userId) async {
    try {
      await _supabase
          .from(DatabaseConstants.paidDaysTable)
          .delete()
          .eq('user_id', userId);
      await _supabase
          .from(DatabaseConstants.paymentsTable)
          .delete()
          .eq('user_id', userId);
      await _supabase
          .from(DatabaseConstants.attendanceTable)
          .delete()
          .eq('user_id', userId);
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'EmployeeCleanupHelper.deleteAllRelatedRecords hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Belirli tarihten önceki kayıtları siler
  Future<void> deleteRecordsBeforeDate(
    int userId,
    int workerId,
    DateTime date,
  ) async {
    try {
      final formattedDate = DateFormatter.toIso8601Date(date);

      await _supabase
          .from(DatabaseConstants.attendanceTable)
          .delete()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .lt('date', formattedDate);

      debugPrint('Devam kayıtları silindi');

      await _supabase
          .from(DatabaseConstants.paidDaysTable)
          .delete()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .lt('date', formattedDate);

      debugPrint('Ödenmiş günler silindi');

      await _supabase
          .from(DatabaseConstants.paymentsTable)
          .delete()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .lt('payment_date', formattedDate);

      debugPrint('Ödeme kayıtları silindi');

      await deleteOrphanedPayments(userId, workerId);
      await updateRemainingPayments(userId, workerId);

      debugPrint(
        '$workerId ID\'li çalışanın $formattedDate tarihinden önceki kayıtları silindi',
      );
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'EmployeeCleanupHelper.deleteRecordsBeforeDate hatası',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sahipsiz ödeme kayıtlarını siler
  Future<void> deleteOrphanedPayments(int userId, int workerId) async {
    try {
      final orphanedPayments = await _supabase
          .from(DatabaseConstants.paymentsTable)
          .select('id')
          .eq('user_id', userId)
          .eq('worker_id', workerId);

      if (orphanedPayments.isEmpty) return;

      final paymentIds = orphanedPayments
          .map<int>((p) => p['id'] as int)
          .toList();

      for (final paymentId in paymentIds) {
        final paidDays = await _supabase
            .from(DatabaseConstants.paidDaysTable)
            .select()
            .eq('payment_id', paymentId)
            .limit(1);

        if (paidDays.isEmpty) {
          await _supabase
              .from(DatabaseConstants.paymentsTable)
              .delete()
              .eq('id', paymentId);
          debugPrint('Sahipsiz ödeme kaydı silindi: $paymentId');
        }
      }
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'EmployeeCleanupHelper.deleteOrphanedPayments hatası',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Kalan ödemelerin gün sayılarını günceller
  Future<void> updateRemainingPayments(int userId, int workerId) async {
    try {
      final payments = await _supabase
          .from(DatabaseConstants.paymentsTable)
          .select('id')
          .eq('user_id', userId)
          .eq('worker_id', workerId);

      for (final payment in payments) {
        final paymentId = payment['id'] as int;

        final fullDaysResult = await _supabase
            .from(DatabaseConstants.paidDaysTable)
            .select()
            .eq('payment_id', paymentId)
            .eq('status', DatabaseConstants.statusFullDay);

        final fullDays = fullDaysResult.length;

        final halfDaysResult = await _supabase
            .from(DatabaseConstants.paidDaysTable)
            .select()
            .eq('payment_id', paymentId)
            .eq('status', DatabaseConstants.statusHalfDay);

        final halfDays = halfDaysResult.length;

        await _supabase
            .from(DatabaseConstants.paymentsTable)
            .update({'full_days': fullDays, 'half_days': halfDays})
            .eq('id', paymentId);

        debugPrint(
          'Ödeme kaydı güncellendi: $paymentId (Tam: $fullDays, Yarım: $halfDays)',
        );
      }
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'EmployeeCleanupHelper.updateRemainingPayments hatası',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
