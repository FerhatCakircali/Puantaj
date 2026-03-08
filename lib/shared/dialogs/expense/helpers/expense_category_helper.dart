import '../../../../models/expense.dart';

/// Masraf kategori yardımcı sınıfı
class ExpenseCategoryHelper {
  /// Kategori enum'ını Türkçe isme çevirir
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
}
