import 'package:flutter/foundation.dart';
import '../../../models/payment.dart';
import '../../../models/attendance.dart';
import '../../../data/local/hive_service.dart';
import '../../../data/local/sync_manager.dart';
import '../../../core/di/service_locator.dart';
import '../repositories/payment_repository.dart';
import '../repositories/paid_days_repository.dart';
import '../helpers/payment_calculator.dart';
import '../helpers/payment_notification_helper.dart';

/// Ödeme verilerini offline-first yaklaşımla senkronize eden helper sınıfı
class PaymentSyncHelper {
  final _hiveService = HiveService.instance;
  final _syncManager = SyncManager.instance;
  late final _repository = getIt<PaymentRepository>();
  late final _paidDaysRepository = getIt<PaidDaysRepository>();
  final _calculator = PaymentCalculator();
  final _notificationHelper = PaymentNotificationHelper();

  /// Ödemeyi offline-first yaklaşımla ekler
  ///
  /// [payment] Ödeme bilgisi
  /// [userId] Kullanıcı ID'si
  /// Returns: Eklenen ödeme ID'si (temp veya real)
  Future<int> addPaymentWithSync(Payment payment, int userId) async {
    final tempPaymentId = DateTime.now().millisecondsSinceEpoch;
    final tempPayment = Payment(
      id: tempPaymentId,
      userId: payment.userId,
      workerId: payment.workerId,
      fullDays: payment.fullDays,
      halfDays: payment.halfDays,
      paymentDate: payment.paymentDate,
      amount: payment.amount,
    );

    await _hiveService.payments.put(tempPaymentId, tempPayment);
    debugPrint('Ödeme cache\'e eklendi (temp ID: $tempPaymentId)');

    if (_syncManager.isOnline) {
      try {
        final paymentMap = payment.toMap();
        final paymentResponse = await _repository.insertPayment(paymentMap);
        final paymentId = paymentResponse['id'] as int;

        await _hiveService.payments.delete(tempPaymentId);
        final realPayment = tempPayment.copyWith(id: paymentId);
        await _hiveService.payments.put(paymentId, realPayment);

        final unpaidAttendance = await _paidDaysRepository.getUnpaidAttendance(
          userId: userId,
          workerId: payment.workerId,
        );

        await _markPaidDays(
          unpaidAttendance: unpaidAttendance,
          fullDays: payment.fullDays,
          halfDays: payment.halfDays,
          paymentId: paymentId,
          userId: userId,
        );

        await _notificationHelper.sendPaymentNotification(payment, userId);

        return paymentId;
      } catch (e) {
        await _syncManager.addPendingSync(
          type: 'payment',
          data: payment.toMap(),
          operation: 'create',
        );

        debugPrint('Offline: Ödeme senkronizasyon kuyruğuna eklendi');
        return tempPaymentId;
      }
    } else {
      await _syncManager.addPendingSync(
        type: 'payment',
        data: payment.toMap(),
        operation: 'create',
      );

      debugPrint('Offline: Ödeme senkronizasyon kuyruğuna eklendi');
      return tempPaymentId;
    }
  }

  /// Ödenmiş günleri işaretler
  ///
  /// [unpaidAttendance] Ödenmemiş devamsızlık listesi
  /// [fullDays] Ödenecek tam gün sayısı
  /// [halfDays] Ödenecek yarım gün sayısı
  /// [paymentId] Ödeme ID'si
  /// [userId] Kullanıcı ID'si
  Future<void> _markPaidDays({
    required List<Attendance> unpaidAttendance,
    required int fullDays,
    required int halfDays,
    required int paymentId,
    required int userId,
  }) async {
    int fullDaysToMark = fullDays;
    int halfDaysToMark = halfDays;

    for (var record in unpaidAttendance) {
      if (record.status == AttendanceStatus.fullDay && fullDaysToMark > 0) {
        await _paidDaysRepository.markDayAsPaid(
          userId: userId,
          workerId: record.workerId,
          date: record.date,
          status: _calculator.attendanceStatusToString(record.status),
          paymentId: paymentId,
        );
        fullDaysToMark--;
      } else if (record.status == AttendanceStatus.halfDay &&
          halfDaysToMark > 0) {
        await _paidDaysRepository.markDayAsPaid(
          userId: userId,
          workerId: record.workerId,
          date: record.date,
          status: _calculator.attendanceStatusToString(record.status),
          paymentId: paymentId,
        );
        halfDaysToMark--;
      }

      if (fullDaysToMark <= 0 && halfDaysToMark <= 0) break;
    }
  }

  /// Hata durumunda temp payment'ı cache'den temizler
  ///
  /// [tempPaymentId] Silinecek temp payment ID'si
  Future<void> cleanupTempPayment(int? tempPaymentId) async {
    if (tempPaymentId != null) {
      await _hiveService.payments.delete(tempPaymentId);
      debugPrint('Temp ödeme cache\'den silindi');
    }
  }
}
