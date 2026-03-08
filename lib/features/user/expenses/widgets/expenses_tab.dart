import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../models/expense.dart';
import '../controllers/expense_controller.dart';
import 'expense_summary_cards.dart';
import 'expense_list_tile.dart';
import 'expense_empty_state.dart';
import 'expense_category_filter.dart';
import 'expense_search_bar.dart';
import 'expense_total_cards.dart';
import '../dialogs/add_expense_dialog.dart';
import '../dialogs/expense_detail_dialog.dart';

/// Masraflar tab widget'ı
class ExpensesTab extends StatefulWidget {
  const ExpensesTab({super.key});

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  final ExpenseController _controller = ExpenseController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  double _monthlyTotal = 0;
  double _overallTotal = 0;
  int _expenseCount = 0;
  bool _isLoading = true;

  ExpenseCategory? _selectedCategory;

  static const Color primaryColor = Color(0xFF4338CA);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    _searchController.clear();
    _selectedCategory = null;

    try {
      final data = await _controller.loadExpenseData();

      if (!mounted) return;

      setState(() {
        _expenses = data.expenses;
        _filteredExpenses = data.expenses;
        _monthlyTotal = data.monthlyTotal;
        _overallTotal = data.overallTotal;
        _expenseCount = data.expenseCount;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('⚠️ Masraf verileri yükleme hatası: $e');

      if (!mounted) return;

      setState(() => _isLoading = false);
    }
  }

  void _filterExpenses(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _filteredExpenses = _controller.filterExpenses(
            _expenses,
            query,
            _selectedCategory,
          );
        });
      }
    });
  }

  void _filterByCategory(ExpenseCategory? category) {
    setState(() {
      _selectedCategory = category;
      _filteredExpenses = _controller.filterExpenses(
        _expenses,
        _searchController.text,
        category,
      );
    });
  }

  double _calculateMonthlyTotal() {
    if (_filteredExpenses.isEmpty) return 0.0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return _filteredExpenses
        .where(
          (expense) =>
              expense.expenseDate.isAfter(
                startOfMonth.subtract(const Duration(days: 1)),
              ) &&
              expense.expenseDate.isBefore(
                endOfMonth.add(const Duration(days: 1)),
              ),
        )
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double _calculateOverallTotal() {
    if (_filteredExpenses.isEmpty) return 0.0;
    return _filteredExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  void _showAddExpenseDialog() {
    AddExpenseDialog.show(context, onExpenseAdded: _loadData);
  }

  void _showExpenseDetails(Expense expense) {
    ExpenseDetailDialog.show(
      context,
      expense: expense,
      onExpenseUpdated: _loadData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: h * 0.005),
                    ExpenseSummaryCards(
                      monthlyTotal: _monthlyTotal,
                      overallTotal: _overallTotal,
                      expenseCount: _expenseCount,
                    ),
                    SizedBox(height: h * 0.015),
                    ExpenseCategoryFilter(
                      selectedCategory: _selectedCategory,
                      onCategorySelected: _filterByCategory,
                    ),
                    SizedBox(height: h * 0.015),
                    ExpenseSearchBar(
                      controller: _searchController,
                      onChanged: _filterExpenses,
                    ),
                    SizedBox(height: h * 0.015),
                    ExpenseTotalCards(
                      monthlyTotal: _calculateMonthlyTotal(),
                      overallTotal: _calculateOverallTotal(),
                    ),
                    SizedBox(height: h * 0.015),
                    Expanded(
                      child: _expenses.isEmpty
                          ? const ExpenseEmptyState()
                          : _filteredExpenses.isEmpty
                          ? const ExpenseNoSearchResults()
                          : ListView.builder(
                              padding: EdgeInsets.only(bottom: h * 0.02),
                              itemCount: _filteredExpenses.length,
                              cacheExtent: h * 0.5,
                              itemBuilder: (context, index) {
                                final expense = _filteredExpenses[index];
                                return RepaintBoundary(
                                  child: ExpenseListTile(
                                    expense: expense,
                                    onTap: () => _showExpenseDetails(expense),
                                    primaryColor: primaryColor,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
