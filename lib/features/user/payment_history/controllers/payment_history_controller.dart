import 'package:flutter/material.dart';
import '../../../../services/payment_service.dart';
import '../../../../core/di/service_locator.dart';

/// Ödeme geçmişi iş mantığı kontrolcüsü
class PaymentHistoryController {
  final PaymentService _paymentService;

  PaymentHistoryController({PaymentService? paymentService})
    : _paymentService = paymentService ?? getIt<PaymentService>();

  /// Belirtilen tarih aralığındaki ödemeleri yükler
  Future<List<Map<String, dynamic>>> loadPayments({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await _paymentService.getUserPaymentHistory(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('Ödeme geçmişi yükleme hatası: $e');
      rethrow;
    }
  }

  /// Ödemeleri çalışan adına göre filtreler
  List<Map<String, dynamic>> filterPayments(
    List<Map<String, dynamic>> payments,
    String query,
  ) {
    if (query.isEmpty) {
      return payments;
    }

    return payments.where((payment) {
      final workerName = payment['workers']['full_name'] as String;
      return workerName.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// Ödeme kaydını günceller
  Future<bool> updatePayment({
    required int paymentId,
    required int fullDays,
    required int halfDays,
    required double amount,
  }) async {
    try {
      return await _paymentService.updatePayment(
        paymentId: paymentId,
        fullDays: fullDays,
        halfDays: halfDays,
        amount: amount,
      );
    } catch (e) {
      debugPrint('Ödeme güncelleme hatası: $e');
      rethrow;
    }
  }

  /// Ödeme kaydını siler
  Future<bool> deletePayment(int paymentId) async {
    try {
      return await _paymentService.deletePayment(paymentId);
    } catch (e) {
      debugPrint('Ödeme silme hatası: $e');
      rethrow;
    }
  }

  /// Belirli bir ödeme hariç ödenmemiş günleri getirir
  Future<Map<String, int>> getUnpaidDaysExcludingPayment(
    int workerId,
    int paymentId,
  ) async {
    return await _paymentService.getUnpaidDaysExcludingPayment(
      workerId,
      paymentId,
    );
  }

  /// Ödeme detaylarını parse eder
  PaymentDetails parsePaymentDetails(Map<String, dynamic> payment) {
    final id = payment['id'] as int;
    final workerId = payment['worker_id'] as int;
    final workerName = payment['workers']['full_name'] as String;
    final fullDays = payment['full_days'] as int;
    final halfDays = payment['half_days'] as int;
    final amount = (payment['amount'] as num).toDouble();
    final paymentDate = DateTime.parse(payment['payment_date'] as String);

    DateTime displayTime;
    if (payment['updated_at'] != null) {
      displayTime = DateTime.parse(payment['updated_at'] as String).toLocal();
    } else if (payment['created_at'] != null) {
      displayTime = DateTime.parse(payment['created_at'] as String).toLocal();
    } else {
      displayTime = paymentDate;
    }

    return PaymentDetails(
      id: id,
      workerId: workerId,
      workerName: workerName,
      fullDays: fullDays,
      halfDays: halfDays,
      amount: amount,
      paymentDate: paymentDate,
      displayTime: displayTime,
    );
  }
}

/// Ödeme detayları model sınıfı
class PaymentDetails {
  final int id;
  final int workerId;
  final String workerName;
  final int fullDays;
  final int halfDays;
  final double amount;
  final DateTime paymentDate;
  final DateTime displayTime;

  PaymentDetails({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.fullDays,
    required this.halfDays,
    required this.amount,
    required this.paymentDate,
    required this.displayTime,
  });
}
