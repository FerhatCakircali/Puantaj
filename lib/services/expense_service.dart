import '../models/expense.dart';
import '../core/error_handling/error_handler_mixin.dart';
import 'auth_service.dart';
import 'expense/repositories/expense_repository.dart';
import 'shared/base_user_helper.dart';

/// Masraf yönetimi servisi
class ExpenseService with ErrorHandlerMixin {
  final ExpenseRepository _repository;
  final BaseUserHelper _userHelper;

  ExpenseService({
    AuthService? authService,
    ExpenseRepository? repository,
    BaseUserHelper? userHelper,
  }) : _repository = repository ?? ExpenseRepository(),
       _userHelper = userHelper ?? BaseUserHelper(authService ?? AuthService());

  Future<List<Expense>> getExpenses() async {
    return handleError(
      () => _userHelper.executeWithUserId(
        (userId) => _repository.getExpenses(userId),
        defaultValue: [],
      ),
      [],
      context: 'ExpenseService.getExpenses',
    );
  }

  Future<List<Expense>> getExpensesByCategory(ExpenseCategory category) async {
    return handleError(
      () => _userHelper.executeWithUserId(
        (userId) => _repository.getExpensesByCategory(userId, category),
        defaultValue: [],
      ),
      [],
      context: 'ExpenseService.getExpensesByCategory',
    );
  }

  Future<Map<ExpenseCategory, double>> getCategoryTotals() async {
    return handleError(
      () async => await _userHelper.executeWithUserId((userId) async {
        final Map<ExpenseCategory, double> totals = {};
        for (var category in ExpenseCategory.values) {
          totals[category] = await _repository.getCategoryTotal(
            userId,
            category,
          );
        }
        return totals;
      }, defaultValue: {}),
      {},
      context: 'ExpenseService.getCategoryTotals',
    );
  }

  Future<int> addExpense(Expense expense) async {
    return handleErrorWithThrow(
      () => _userHelper.executeWithUserId(
        (userId) => _repository.addExpense(expense, userId),
        defaultValue: -1,
      ),
      context: 'ExpenseService.addExpense',
      userMessage: 'Masraf eklenirken hata oluştu',
    );
  }

  Future<int> updateExpense(Expense expense) async {
    return handleErrorWithThrow(
      () async => await _userHelper.executeWithUserId((userId) async {
        final success = await _repository.updateExpense(expense, userId);
        return success ? 1 : -1;
      }, defaultValue: -1),
      context: 'ExpenseService.updateExpense',
      userMessage: 'Masraf güncellenirken hata oluştu',
    );
  }

  Future<int> deleteExpense(int id) async {
    return handleErrorWithThrow(
      () async => await _userHelper.executeWithUserId((userId) async {
        final success = await _repository.deleteExpense(id, userId);
        return success ? 1 : -1;
      }, defaultValue: -1),
      context: 'ExpenseService.deleteExpense',
      userMessage: 'Masraf silinirken hata oluştu',
    );
  }

  /// En çok harcanan kategoriyi getir
  Future<Map<String, dynamic>?> getTopExpenseCategory() async {
    return handleError(
      () async {
        final categoryTotals = await getCategoryTotals();
        if (categoryTotals.isEmpty) return null;

        var topCategory = categoryTotals.entries.first.key;
        var topAmount = categoryTotals.entries.first.value;

        for (var entry in categoryTotals.entries) {
          if (entry.value > topAmount) {
            topCategory = entry.key;
            topAmount = entry.value;
          }
        }

        return {'category': topCategory, 'amount': topAmount};
      },
      null,
      context: 'ExpenseService.getTopExpenseCategory',
    );
  }

  /// Aylık masraf toplamını getir
  Future<double> getMonthlyExpenses(
    DateTime monthStart,
    DateTime monthEnd,
  ) async {
    return handleError(
      () async => await _userHelper.executeWithUserId((userId) async {
        final expenses = await _repository.getExpenses(userId);
        double total = 0.0;
        for (var expense in expenses) {
          if (expense.expenseDate.isAfter(
                monthStart.subtract(const Duration(days: 1)),
              ) &&
              expense.expenseDate.isBefore(
                monthEnd.add(const Duration(days: 1)),
              )) {
            total += expense.amount;
          }
        }
        return total;
      }, defaultValue: 0.0),
      0.0,
      context: 'ExpenseService.getMonthlyExpenses',
    );
  }

  /// Tarih aralığına göre masrafları getir
  Future<List<Expense>> getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return handleError(
      () async => await _userHelper.executeWithUserId((userId) async {
        final expenses = await _repository.getExpenses(userId);
        return expenses
            .where(
              (expense) =>
                  expense.expenseDate.isAfter(
                    startDate.subtract(const Duration(days: 1)),
                  ) &&
                  expense.expenseDate.isBefore(
                    endDate.add(const Duration(days: 1)),
                  ),
            )
            .toList();
      }, defaultValue: []),
      [],
      context: 'ExpenseService.getExpensesByDateRange',
    );
  }
}
