import '../../../../../core/validation/base_validator.dart';

/// Masraf form validasyon sınıfı
class ExpenseFormValidator extends BaseValidator {
  static final _instance = ExpenseFormValidator._();
  ExpenseFormValidator._();
  factory ExpenseFormValidator() => _instance;

  /// Masraf türü validasyonu
  String? validateExpenseType(String? value) {
    return validateRequired(value, fieldName: 'Masraf türü');
  }

  /// Tutar validasyonu
  String? validateAmountField(String? value) {
    return validateAmount(value, fieldName: 'Tutar');
  }

  /// Tutar string'ini double'a çevirir
  double parseAmountField(String value) {
    return parseAmount(value);
  }
}
