import 'package:flutter/foundation.dart';
import '../../../models/expense.dart';
import '../../../core/repositories/base_crud_repository.dart';
import '../../../core/constants/database_constants.dart';

/// Masraf CRUD işlemlerini yöneten repository
class ExpenseRepository extends BaseCrudRepository<Expense> {
  @override
  String get tableName => DatabaseConstants.expensesTable;

  @override
  Map<String, dynamic> toMap(Expense entity) => entity.toMap();

  @override
  Expense fromMap(Map<String, dynamic> map) => Expense.fromMap(map);

  Future<List<Expense>> getExpenses(int userId) async {
    debugPrint('Masraflar getiriliyor...');
    final expenses = await getAll(
      userId,
      orderBy: 'expense_date',
      ascending: false,
    );
    debugPrint('${expenses.length} masraf getirildi');
    return expenses;
  }

  Future<List<Expense>> getExpensesByCategory(
    int userId,
    ExpenseCategory category,
  ) async {
    return executeQuery(
      () async {
        debugPrint('Kategori masrafları getiriliyor: ${category.displayName}');
        final results = await supabase
            .from(tableName)
            .select()
            .eq(userIdField, userId)
            .eq('category', category.value)
            .order('expense_date', ascending: false);
        final expenses = results.map((map) => fromMap(map)).toList();
        debugPrint('${expenses.length} masraf getirildi');
        return expenses;
      },
      [],
      context: 'ExpenseRepository.getExpensesByCategory',
    );
  }

  Future<double> getCategoryTotal(int userId, ExpenseCategory category) async {
    return executeQuery(
      () async {
        final result = await supabase.rpc(
          'get_expenses_by_category',
          params: {'user_id_param': userId, 'category_param': category.value},
        );
        return (result as num?)?.toDouble() ?? 0.0;
      },
      0.0,
      context: 'ExpenseRepository.getCategoryTotal',
    );
  }

  Future<int> addExpense(Expense expense, int userId) => add(expense, userId);

  Future<bool> updateExpense(Expense expense, int userId) =>
      update(expense, expense.id, userId);

  Future<bool> deleteExpense(int id, int userId) => delete(id, userId);
}
