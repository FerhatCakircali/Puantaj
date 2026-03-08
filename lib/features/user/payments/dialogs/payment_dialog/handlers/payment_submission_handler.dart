import 'package:flutter/material.dart';
import '../../../../../../models/employee.dart';
import '../../../../../../models/advance.dart';
import '../../../../../../services/advance_service.dart';
import '../../../../../../utils/currency_formatter.dart';
import '../controllers/payment_dialog_controller.dart';
import '../validators/payment_validator.dart';

/// Ödeme gönderme işlemlerini yöneten sınıf
///
/// Ödeme yapma, avans düşme ve hata yönetimi işlemlerini koordine eder
class PaymentSubmissionHandler {
  final PaymentDialogController _controller;
  final AdvanceService _advanceService;

  PaymentSubmissionHandler({
    required PaymentDialogController controller,
    AdvanceService? advanceService,
  }) : _controller = controller,
       _advanceService = advanceService ?? AdvanceService();

  /// Ödeme işlemini gerçekleştirir
  Future<PaymentResult> submitPayment({
    required Employee employee,
    required int fullDays,
    required int halfDays,
    required double amount,
    required int availableFullDays,
    required int availableHalfDays,
    required bool deductAdvances,
    required List<Advance> pendingAdvances,
    required double totalPendingAdvances,
  }) async {
    final validationError = PaymentFormValidator.validate(
      fullDays: fullDays,
      halfDays: halfDays,
      amount: amount,
      availableFullDays: availableFullDays,
      availableHalfDays: availableHalfDays,
    );

    if (validationError != null) {
      return PaymentResult.error(validationError);
    }

    var finalAmount = amount;

    if (deductAdvances && totalPendingAdvances > 0) {
      final advanceError = PaymentFormValidator.validateAdvanceDeduction(
        paymentAmount: amount,
        advanceAmount: totalPendingAdvances,
      );

      if (advanceError != null) {
        return PaymentResult.error(advanceError);
      }

      finalAmount = amount - totalPendingAdvances;
    }

    try {
      final paymentId = await _controller.makePayment(
        employee: employee,
        fullDays: fullDays,
        halfDays: halfDays,
        amount: finalAmount,
      );

      if (deductAdvances && pendingAdvances.isNotEmpty && paymentId != null) {
        await _deductAdvances(pendingAdvances, paymentId);
      }

      return PaymentResult.success(
        deductedAdvances: deductAdvances,
        advanceAmount: totalPendingAdvances,
      );
    } catch (e, stackTrace) {
      debugPrint('Ödeme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      return PaymentResult.error('Ödeme kaydedilirken bir hata oluştu: $e');
    }
  }

  /// Bekleyen avansları düşülmüş olarak işaretler
  Future<void> _deductAdvances(List<Advance> advances, int paymentId) async {
    for (final advance in advances) {
      if (advance.id != null) {
        await _advanceService.markAsDeducted(advance.id!, paymentId);
      }
    }
  }
}

/// Ödeme sonuç sınıfı
class PaymentResult {
  final bool isSuccess;
  final String? errorMessage;
  final bool deductedAdvances;
  final double advanceAmount;

  const PaymentResult._({
    required this.isSuccess,
    this.errorMessage,
    this.deductedAdvances = false,
    this.advanceAmount = 0,
  });

  factory PaymentResult.success({
    required bool deductedAdvances,
    required double advanceAmount,
  }) {
    return PaymentResult._(
      isSuccess: true,
      deductedAdvances: deductedAdvances,
      advanceAmount: advanceAmount,
    );
  }

  factory PaymentResult.error(String message) {
    return PaymentResult._(isSuccess: false, errorMessage: message);
  }

  /// Başarı mesajını oluşturur
  String getSuccessMessage() {
    String message = 'Ödeme başarıyla kaydedildi';
    if (deductedAdvances && advanceAmount > 0) {
      message +=
          '\n${CurrencyFormatter.formatWithSymbol(advanceAmount)} avans düşüldü';
    }
    return message;
  }
}
