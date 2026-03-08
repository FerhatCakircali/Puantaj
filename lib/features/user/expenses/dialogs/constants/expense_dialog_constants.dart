import 'package:flutter/material.dart';

/// Masraf dialog'ları için sabit değerler
class ExpenseDialogConstants {
  static const Color primaryColor = Color(0xFF4338CA);
  static const double maxDialogWidth = 500.0;
  static const double borderRadius = 12.0;
  static const double iconBorderRadius = 12.0;

  static const String expenseTypeHint = 'Örn: 1 ton demir';
  static const String amountHint = '0';
  static const String descriptionHint = 'Masraf açıklaması...';

  static const String expenseTypeLabel = 'Masraf Türü';
  static const String categoryLabel = 'Kategori';
  static const String amountLabel = 'Tutar (₺)';
  static const String dateLabel = 'Tarih';
  static const String descriptionLabel = 'Açıklama (Opsiyonel)';
}
