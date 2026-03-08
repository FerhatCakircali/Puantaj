import 'package:flutter/material.dart';
import '../../../../../../models/expense.dart';

/// Masraf kategorisi yardımcı sınıfı
class ExpenseCategoryHelper {
  /// Kategori adını döndürür
  static String getCategoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.malzeme:
        return 'Malzeme';
      case ExpenseCategory.ulasim:
        return 'Ulaşım';
      case ExpenseCategory.ekipman:
        return 'Ekipman';
      case ExpenseCategory.diger:
        return 'Diğer';
    }
  }

  /// Kategori rengini döndürür
  static Color getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.malzeme:
        return Colors.blue;
      case ExpenseCategory.ulasim:
        return Colors.orange;
      case ExpenseCategory.ekipman:
        return Colors.green;
      case ExpenseCategory.diger:
        return Colors.purple;
    }
  }

  /// Kategori ikonunu döndürür
  static IconData getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.malzeme:
        return Icons.inventory_2;
      case ExpenseCategory.ulasim:
        return Icons.local_shipping;
      case ExpenseCategory.ekipman:
        return Icons.construction;
      case ExpenseCategory.diger:
        return Icons.more_horiz;
    }
  }
}
