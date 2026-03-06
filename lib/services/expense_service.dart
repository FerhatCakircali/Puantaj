import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../core/app_globals.dart';
import '../utils/date_formatter.dart';
import '../utils/currency_formatter.dart';
import '../core/error_logger.dart';
import 'auth_service.dart';

/// Masraf yönetimi servisi
/// İş masraflarının (malzeme, ulaşım vb.) CRUD işlemlerini yönetir
class ExpenseService {
  final _authService = AuthService();

  /// Yöneticinin tüm masraflarını getir
  Future<List<Expense>> getExpenses() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return [];

      debugPrint('🏗️ Masraflar getiriliyor...');

      final results = await supabase
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .order('expense_date', ascending: false);

      final expenses = results.map((map) => Expense.fromMap(map)).toList();

      debugPrint('✅ ${expenses.length} masraf getirildi');
      return expenses;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'ExpenseService.getExpenses hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Kategoriye göre masrafları getir
  Future<List<Expense>> getExpensesByCategory(ExpenseCategory category) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return [];

      debugPrint(
        '🏗️ Kategori masrafları getiriliyor: ${category.displayName}',
      );

      final results = await supabase
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .eq('category', category.value)
          .order('expense_date', ascending: false);

      final expenses = results.map((map) => Expense.fromMap(map)).toList();

      debugPrint('✅ ${expenses.length} masraf getirildi');
      return expenses;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'ExpenseService.getExpensesByCategory hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Kategorilere göre toplam masrafları getir
  Future<Map<ExpenseCategory, double>> getCategoryTotals() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return {};

      debugPrint('🏗️ Kategori toplamları hesaplanıyor...');

      final Map<ExpenseCategory, double> totals = {};

      for (var category in ExpenseCategory.values) {
        final result = await supabase.rpc(
          'get_expenses_by_category',
          params: {'user_id_param': userId, 'category_param': category.value},
        );

        final total = (result as num?)?.toDouble() ?? 0.0;
        totals[category] = total;

        debugPrint(
          '  ${category.displayName}: ${CurrencyFormatter.formatWithSymbol(total)}',
        );
      }

      debugPrint('✅ Kategori toplamları hesaplandı');
      return totals;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'ExpenseService.getCategoryTotals hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  /// En çok harcanan kategoriyi getir
  Future<Map<String, dynamic>?> getTopExpenseCategory() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return null;

      debugPrint('🏗️ En çok harcanan kategori hesaplanıyor...');

      final result = await supabase.rpc(
        'get_top_expense_category',
        params: {'user_id_param': userId},
      );

      if (result == null || result.isEmpty) {
        debugPrint('⚠️ Henüz masraf kaydı yok');
        return null;
      }

      final topCategory = result.first;
      final categoryValue = topCategory['category'] as String;
      final totalAmount = (topCategory['total_amount'] as num).toDouble();

      final category = ExpenseCategory.fromString(categoryValue);

      debugPrint(
        '✅ En çok harcanan: ${category.displayName} - ${CurrencyFormatter.formatWithSymbol(totalAmount)}',
      );

      return {'category': category, 'amount': totalAmount};
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'ExpenseService.getTopExpenseCategory hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Yeni masraf ekle
  Future<Expense> addExpense(Expense expense) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        ErrorLogger.instance.logError('ExpenseService.addExpense: userId null');
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      debugPrint(
        '🏗️ Yeni masraf ekleniyor: ${expense.expenseType} - ${expense.amount}',
      );

      final expenseMap = expense.copyWith(userId: userId).toMap();
      debugPrint('🏗️ Masraf map: $expenseMap');

      final result = await supabase
          .from('expenses')
          .insert(expenseMap)
          .select()
          .single();

      final newExpense = Expense.fromMap(result);

      debugPrint('✅ Masraf başarıyla eklendi (ID: ${newExpense.id})');

      return newExpense;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'ExpenseService.addExpense hatası',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Masraf güncelle
  Future<void> updateExpense(Expense expense) async {
    try {
      if (expense.id == null) {
        throw Exception('Masraf ID bulunamadı');
      }

      debugPrint('🏗️ Masraf güncelleniyor: ID=${expense.id}');

      final expenseMap = expense.toMap();
      expenseMap.remove('id'); // ID'yi güncelleme map'inden çıkar

      await supabase.from('expenses').update(expenseMap).eq('id', expense.id!);

      debugPrint('✅ Masraf başarıyla güncellendi');
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'ExpenseService.updateExpense hatası',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Masraf sil
  Future<void> deleteExpense(int expenseId) async {
    try {
      debugPrint('🏗️ Masraf siliniyor: ID=$expenseId');

      await supabase.from('expenses').delete().eq('id', expenseId);

      debugPrint('✅ Masraf başarıyla silindi');
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'ExpenseService.deleteExpense hatası',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Aylık masraf toplamını getir
  Future<double> getMonthlyExpenses(
    DateTime monthStart,
    DateTime monthEnd,
  ) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return 0.0;

      debugPrint('🏗️ Aylık masraf hesaplanıyor: $monthStart - $monthEnd');

      final result = await supabase.rpc(
        'get_monthly_expenses',
        params: {
          'user_id_param': userId,
          'month_start': DateFormatter.toIso8601Date(monthStart),
          'month_end': DateFormatter.toIso8601Date(monthEnd),
        },
      );

      final monthlyTotal = (result as num?)?.toDouble() ?? 0.0;

      debugPrint(
        '✅ Aylık masraf: ${CurrencyFormatter.formatWithSymbol(monthlyTotal)}',
      );
      return monthlyTotal;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'ExpenseService.getMonthlyExpenses hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return 0.0;
    }
  }

  /// Tarih aralığına göre masrafları getir
  Future<List<Expense>> getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return [];

      debugPrint(
        '🏗️ Tarih aralığı masrafları getiriliyor: $startDate - $endDate',
      );

      final results = await supabase
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .gte('expense_date', DateFormatter.toIso8601Date(startDate))
          .lte('expense_date', DateFormatter.toIso8601Date(endDate))
          .order('expense_date', ascending: false);

      final expenses = results.map((map) => Expense.fromMap(map)).toList();

      debugPrint('✅ ${expenses.length} masraf getirildi');
      return expenses;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'ExpenseService.getExpensesByDateRange hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
}
