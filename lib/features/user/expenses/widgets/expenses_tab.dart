import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../models/expense.dart';
import '../controllers/expense_controller.dart';
import 'expense_summary_cards.dart';
import 'expense_list_tile.dart';
import 'expense_empty_state.dart';
import 'expense_no_search_results.dart';
import 'expense_category_filters.dart';
import 'expense_total_display.dart';
import 'expense_search_bar.dart';
import '../dialogs/add_expense_dialog.dart';
import '../dialogs/expense_detail_dialog.dart';

/// Masraflar tab widget'ı
///
/// Masrafları listeler, filtreler ve yönetir.
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
  bool _showMonthlyTotal = true;

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

      debugPrint('Masraf verileri yüklendi: ${_expenses.length} masraf');
    } catch (e) {
      debugPrint('Masraf verileri yükleme hatası: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
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

  double _calculateFilteredTotal() {
    if (_filteredExpenses.isEmpty) return 0.0;

    if (_showMonthlyTotal) {
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
    } else {
      return _filteredExpenses.fold(
        0.0,
        (sum, expense) => sum + expense.amount,
      );
    }
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
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
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ExpenseCategoryFilters(
                            selectedCategory: _selectedCategory,
                            onCategorySelected: _filterByCategory,
                          ),
                        ),
                        SizedBox(width: w * 0.02),
                        Expanded(
                          flex: 2,
                          child: ExpenseTotalDisplay(
                            filteredTotal: _calculateFilteredTotal(),
                            showMonthlyTotal: _showMonthlyTotal,
                            onToggle: () {
                              setState(() {
                                _showMonthlyTotal = !_showMonthlyTotal;
                              });
                            },
                            primaryColor: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: h * 0.015),
                    ExpenseSearchBar(
                      controller: _searchController,
                      onChanged: _filterExpenses,
                      onClear: () {
                        _searchController.clear();
                        _filterExpenses('');
                      },
                    ),
                    SizedBox(height: h * 0.015),
                    Expanded(child: _buildExpenseList(h)),
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

  Widget _buildExpenseList(double h) {
    if (_expenses.isEmpty) {
      return const ExpenseEmptyState();
    }

    if (_filteredExpenses.isEmpty) {
      return const ExpenseNoSearchResults();
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: h * 0.02),
      itemCount: _filteredExpenses.length,
      cacheExtent: h * 0.5,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
    );
  }
}
