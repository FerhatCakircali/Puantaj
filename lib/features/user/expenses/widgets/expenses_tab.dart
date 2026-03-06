import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../models/expense.dart';
import '../controllers/expense_controller.dart';
import 'expense_summary_cards.dart';
import 'expense_list_tile.dart';
import 'expense_empty_state.dart';
import 'category_chip.dart';
import '../dialogs/add_expense_dialog.dart';
import '../dialogs/expense_detail_dialog.dart';
import '../../../user/payments/utils/currency_formatter.dart';

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
  bool _showMonthlyTotal = true; // true = Bu Ay Toplam, false = Toplam

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
      // Bu ay toplam - sadece bu ayki masrafları hesapla
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
      // Toplam - tüm masrafları hesapla
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
                    // Özet kartları
                    ExpenseSummaryCards(
                      monthlyTotal: _monthlyTotal,
                      overallTotal: _overallTotal,
                      expenseCount: _expenseCount,
                    ),
                    SizedBox(height: h * 0.015),
                    // Kategori filtreleme + Toplam göstergeleri
                    Row(
                      children: [
                        Expanded(flex: 3, child: _buildCategoryFilters()),
                        SizedBox(width: w * 0.02),
                        Expanded(flex: 2, child: _buildCompactTotalDisplay()),
                      ],
                    ),
                    SizedBox(height: h * 0.015),
                    // Arama çubuğu
                    _buildSearchBar(theme),
                    SizedBox(height: h * 0.015),
                    // Liste
                    Expanded(
                      child: _expenses.isEmpty
                          ? const ExpenseEmptyState()
                          : _filteredExpenses.isEmpty
                          ? const ExpenseNoSearchResults()
                          : ListView.builder(
                              padding: EdgeInsets.only(bottom: h * 0.02),
                              itemCount: _filteredExpenses.length,
                              cacheExtent: h * 0.5,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior
                                      .onDrag,                               itemBuilder: (context, index) {
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

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          CategoryChip(
            category: null,
            isSelected: _selectedCategory == null,
            onTap: () => _filterByCategory(null),
          ),
          const SizedBox(width: 8),
          CategoryChip(
            category: ExpenseCategory.malzeme,
            isSelected: _selectedCategory == ExpenseCategory.malzeme,
            onTap: () => _filterByCategory(ExpenseCategory.malzeme),
          ),
          const SizedBox(width: 8),
          CategoryChip(
            category: ExpenseCategory.ulasim,
            isSelected: _selectedCategory == ExpenseCategory.ulasim,
            onTap: () => _filterByCategory(ExpenseCategory.ulasim),
          ),
          const SizedBox(width: 8),
          CategoryChip(
            category: ExpenseCategory.ekipman,
            isSelected: _selectedCategory == ExpenseCategory.ekipman,
            onTap: () => _filterByCategory(ExpenseCategory.ekipman),
          ),
          const SizedBox(width: 8),
          CategoryChip(
            category: ExpenseCategory.diger,
            isSelected: _selectedCategory == ExpenseCategory.diger,
            onTap: () => _filterByCategory(ExpenseCategory.diger),
          ),
        ],
      ),
    );
  }

  /// Kompakt toplam göstergesi (her zaman görünür)
  Widget _buildCompactTotalDisplay() {
    final filteredTotal = _calculateFilteredTotal();

    return GestureDetector(
      onTap: () {
        setState(() {
          _showMonthlyTotal = !_showMonthlyTotal;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    _showMonthlyTotal ? 'Bu Ay' : 'Toplam',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  _showMonthlyTotal
                      ? Icons.calendar_month
                      : Icons.all_inclusive,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ],
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '₺${CurrencyFormatter.format(filteredTotal)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return TextField(
      controller: _searchController,
      onChanged: _filterExpenses,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: 'Masraf ara...',
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.5)
              : Colors.grey.shade600,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.grey.shade700,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey.shade700,
                ),
                onPressed: () {
                  _searchController.clear();
                  _filterExpenses('');
                },
              )
            : null,
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
