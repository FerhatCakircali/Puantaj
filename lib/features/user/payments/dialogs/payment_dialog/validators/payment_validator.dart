import '../../../../../../utils/currency_formatter.dart';

/// Ödeme form validasyon sınıfı
class PaymentFormValidator {
  /// Ödeme değerlerini doğrular
  ///
  /// Hata varsa hata mesajı döner, yoksa null döner
  static String? validate({
    required int fullDays,
    required int halfDays,
    required double amount,
    required int availableFullDays,
    required int availableHalfDays,
  }) {
    if (fullDays == 0 && halfDays == 0) {
      return 'Lütfen en az bir gün seçin';
    }

    if (fullDays > availableFullDays) {
      return 'Tam gün sayısı mevcut günlerden fazla olamaz';
    }

    if (halfDays > availableHalfDays) {
      return 'Yarım gün sayısı mevcut günlerden fazla olamaz';
    }

    if (amount <= 0) {
      return 'Ödeme tutarı 0\'dan büyük olmalıdır';
    }

    return null;
  }

  /// Avans düşme validasyonu
  ///
  /// Ödeme tutarının avans tutarından az olup olmadığını kontrol eder
  static String? validateAdvanceDeduction({
    required double paymentAmount,
    required double advanceAmount,
  }) {
    if (paymentAmount < advanceAmount) {
      return 'Ödeme tutarı (${CurrencyFormatter.formatWithSymbol(paymentAmount)}) '
          'bekleyen avans tutarından (${CurrencyFormatter.formatWithSymbol(advanceAmount)}) '
          'az olamaz.';
    }
    return null;
  }
}
