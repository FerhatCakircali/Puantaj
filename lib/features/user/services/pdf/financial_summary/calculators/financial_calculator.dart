import '../../../../../../models/payment.dart';
import '../../../../../../models/advance.dart';
import '../../../../../../models/expense.dart';

/// Finansal hesaplamalar için yardımcı sınıf
class FinancialCalculator {
  /// Tüm finansal toplamları hesaplar
  Map<String, double> calculateTotals(
    List<Payment> payments,
    List<Advance> advances,
    List<Expense> expenses,
  ) {
    final totalPayments = payments.fold<double>(0, (sum, p) => sum + p.amount);
    final totalAdvances = advances.fold<double>(0, (sum, a) => sum + a.amount);
    final deductedAdvances = advances
        .where((a) => a.isDeducted)
        .fold<double>(0, (sum, a) => sum + a.amount);
    final pendingAdvances = advances
        .where((a) => !a.isDeducted)
        .fold<double>(0, (sum, a) => sum + a.amount);
    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final totalSpending = totalPayments + totalAdvances + totalExpenses;

    return {
      'totalPayments': totalPayments,
      'totalAdvances': totalAdvances,
      'deductedAdvances': deductedAdvances,
      'pendingAdvances': pendingAdvances,
      'totalExpenses': totalExpenses,
      'totalSpending': totalSpending,
    };
  }

  /// Kategori bazlı masraf toplamlarını hesaplar
  Map<ExpenseCategory, double> calculateCategoryTotals(List<Expense> expenses) {
    final categoryTotals = <ExpenseCategory, double>{};
    for (var expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    return categoryTotals;
  }
}
