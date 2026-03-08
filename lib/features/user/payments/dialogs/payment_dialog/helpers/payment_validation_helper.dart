import 'package:flutter/material.dart';

/// Ödeme validasyon helper'ı
class PaymentValidationHelper {
  /// Tam gün sayısını validate eder ve düzeltir
  static String? validateAndCorrectFullDays(
    String value,
    int availableFullDays,
    TextEditingController controller,
  ) {
    final val = int.tryParse(value) ?? 0;
    if (val > availableFullDays) {
      final corrected = availableFullDays.toString();
      controller.text = corrected;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: corrected.length),
      );
      return corrected;
    }
    return null;
  }

  /// Yarım gün sayısını validate eder ve düzeltir
  static String? validateAndCorrectHalfDays(
    String value,
    int availableHalfDays,
    TextEditingController controller,
  ) {
    final val = int.tryParse(value) ?? 0;
    if (val > availableHalfDays) {
      final corrected = availableHalfDays.toString();
      controller.text = corrected;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: corrected.length),
      );
      return corrected;
    }
    return null;
  }

  /// Ödeme tutarını parse eder
  static double parseAmount(String text) {
    final cleanText = text.replaceAll('.', '');
    return double.tryParse(cleanText) ?? 0.0;
  }
}
