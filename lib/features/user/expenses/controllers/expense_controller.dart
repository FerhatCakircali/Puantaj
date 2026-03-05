import '../../../../models/expense.dart';
import '../../../../services/expense_service.dart';

/// Masraf ekranı iş mantığı kontrolcüsü
class ExpenseController {
  final ExpenseService _expenseService = ExpenseService();

  /// Tüm masrafları ve istatistikleri yükler
  Future<ExpenseData> loadExpenseData() async {
    final expenses = await _expenseService.getExpenses();
    final categoryTotals = await _expenseService.getCategoryTotals();
    final topCategoryData = await _expenseService.getTopExpenseCategory();

    // Bu ay yapılan masrafları hesapla
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    // Tek loop'ta tüm hesaplamaları yap (daha performanslı)
    double monthlyTotal = 0;
    double overallTotal = 0;

    for (var expense in expenses) {
      overallTotal += expense.amount;

      if (expense.expenseDate.isAfter(
            startOfMonth.subtract(const Duration(days: 1)),
          ) &&
          expense.expenseDate.isBefore(
            endOfMonth.add(const Duration(days: 1)),
          )) {
        monthlyTotal += expense.amount;
      }
    }

    // En çok harcanan kategori
    ExpenseCategory? topCategory;
    if (topCategoryData != null) {
      topCategory = topCategoryData['category'] as ExpenseCategory;
    }

    return ExpenseData(
      expenses: expenses,
      categoryTotals: categoryTotals,
      monthlyTotal: monthlyTotal,
      overallTotal: overallTotal,
      topCategory: topCategory,
      expenseCount: expenses.length,
    );
  }

  /// Masrafları masraf türüne veya kategoriye göre filtreler
  List<Expense> filterExpenses(
    List<Expense> expenses,
    String query,
    ExpenseCategory? categoryFilter,
  ) {
    var filtered = expenses;

    // Kategori filtresi
    if (categoryFilter != null) {
      filtered = filtered
          .where((expense) => expense.category == categoryFilter)
          .toList();
    }

    // Arama filtresi
    if (query.isNotEmpty) {
      filtered = filtered
          .where(
            (expense) =>
                expense.expenseType.toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                expense.category.displayName.toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                (expense.description?.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    return filtered;
  }

  /// Masraf ekle
  Future<void> addExpense(Expense expense) async {
    await _expenseService.addExpense(expense);
  }

  /// Masraf güncelle
  Future<void> updateExpense(Expense expense) async {
    await _expenseService.updateExpense(expense);
  }

  /// Masraf sil
  Future<void> deleteExpense(int expenseId) async {
    await _expenseService.deleteExpense(expenseId);
  }

  /// Kategoriye göre masrafları getir
  Future<List<Expense>> getExpensesByCategory(ExpenseCategory category) async {
    return await _expenseService.getExpensesByCategory(category);
  }

  /// Aylık masraf toplamını getir
  Future<double> getMonthlyExpenses(
    DateTime monthStart,
    DateTime monthEnd,
  ) async {
    return await _expenseService.getMonthlyExpenses(monthStart, monthEnd);
  }
}

/// Masraf verisi model sınıfı
class ExpenseData {
  final List<Expense> expenses;
  final Map<ExpenseCategory, double> categoryTotals;
  final double monthlyTotal;
  final double overallTotal;
  final ExpenseCategory? topCategory;
  final int expenseCount;

  ExpenseData({
    required this.expenses,
    required this.categoryTotals,
    required this.monthlyTotal,
    required this.overallTotal,
    required this.topCategory,
    required this.expenseCount,
  });
}
