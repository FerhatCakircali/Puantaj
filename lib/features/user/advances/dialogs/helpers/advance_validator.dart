import '../../../../../core/validation/base_validator.dart';

/// Avans form validasyon sınıfı
class AdvanceFormValidator extends BaseValidator {
  static final _instance = AdvanceFormValidator._();
  AdvanceFormValidator._();
  factory AdvanceFormValidator() => _instance;

  /// Tutar validasyonu
  String? validateAmountField(String? value) {
    return validateAmount(value, fieldName: 'Tutar');
  }

  /// Çalışan seçimi validasyonu
  String? validateEmployee(dynamic value) {
    if (value == null) {
      return 'Çalışan seçin';
    }
    return null;
  }

  /// Tutar string'ini double'a çevirir
  double parseAmountField(String value) {
    return parseAmount(value);
  }
}
