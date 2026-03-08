import '../../../core/validation/base_validator.dart';
import '../../../models/payment.dart';

/// Ödeme validasyonunu yapan sınıf
class PaymentValidator extends BaseValidator {
  /// Ödemeyi validate eder
  ///
  /// [payment] Validate edilecek ödeme
  /// Throws: [ArgumentError] validation başarısız ise
  void validatePayment(Payment payment) {
    validatePositive(payment.amount, fieldName: 'Ödeme tutarı');
    validatePositive(payment.fullDays, fieldName: 'Tam gün sayısı');
    validatePositive(payment.halfDays, fieldName: 'Yarım gün sayısı');

    if (payment.fullDays == 0 && payment.halfDays == 0 && payment.amount > 0) {
      throw ArgumentError('Gün sayısı olmadan ödeme yapılamaz');
    }

    validateId(payment.workerId, fieldName: 'Çalışan ID');
  }

  /// Ödeme ID'sini validate eder
  ///
  /// [paymentId] Validate edilecek ID
  /// Throws: [ArgumentError] validation başarısız ise
  void validatePaymentId(int paymentId) {
    validateId(paymentId, fieldName: 'Ödeme ID');
  }

  /// Çalışan ID'sini validate eder
  ///
  /// [workerId] Validate edilecek ID
  /// Throws: [ArgumentError] validation başarısız ise
  void validateWorkerId(int workerId) {
    validateId(workerId, fieldName: 'Çalışan ID');
  }
}
