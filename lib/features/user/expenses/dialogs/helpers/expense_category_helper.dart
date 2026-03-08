import '../../../../../models/expense.dart';

/// Masraf kategorisi yardımcı sınıfı
///
/// Kategori enum'larını Türkçe isimlere çevirir.
class ExpenseCategoryHelper {
  /// Kategori enum'unu Türkçe isme çevirir
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
