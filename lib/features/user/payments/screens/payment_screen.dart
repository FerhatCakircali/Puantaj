import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/employee.dart';
import '../controllers/payment_controller.dart';
import '../widgets/payment_bento_summary.dart';
import '../widgets/payment_transaction_tile.dart';
import '../widgets/payment_empty_states.dart';
import '../dialogs/payment_dialog/widgets/payment_dialog.dart';
import '../../advances/widgets/advances_tab.dart';
import '../../expenses/widgets/expenses_tab.dart';

/// Finans yönetim ekranı (Ödemeler, Avanslar, Masraflar)
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PaymentController _controller = PaymentController();
  final TextEditingController _searchController = TextEditingController();

  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  Map<int, Map<String, int>> _unpaidDays = {};
  Map<int, double> _unpaidScores = {};
  bool _isLoading = true;
  double _monthlyPaidAmount = 0;

  static const Color primaryColor = Color(0xFF4338CA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    _searchController.clear();

    try {
      final data = await _controller.loadPaymentData();

      if (!mounted) return;

      setState(() {
        _employees = data.employees;
        _filteredEmployees = data.employees;
        _unpaidDays = data.unpaidDays;
        _unpaidScores = data.unpaidScores;
        _monthlyPaidAmount = data.monthlyPaidAmount;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Payment data yükleme hatası: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterEmployees(String query) {
    setState(() {
      _filteredEmployees = _controller.filterEmployees(_employees, query);
    });
  }

  void _showPaymentDialog(Employee employee) {
    PaymentDialog.show(
      context,
      employee: employee,
      onPaymentComplete: _loadData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Tab Bar (Raporlar sayfası stili)
            Container(
              margin: EdgeInsets.fromLTRB(w * 0.04, h * 0.01, w * 0.04, 0),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: colorScheme.onPrimary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicator: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: w * 0.032,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: w * 0.032,
                ),
                tabs: [
                  Tab(
                    icon: Icon(Icons.payments, size: w * 0.05),
                    text: 'Ödemeler',
                    iconMargin: EdgeInsets.only(bottom: h * 0.005),
                  ),
                  Tab(
                    icon: Icon(Icons.account_balance_wallet, size: w * 0.05),
                    text: 'Avanslar',
                    iconMargin: EdgeInsets.only(bottom: h * 0.005),
                  ),
                  Tab(
                    icon: Icon(Icons.receipt_long, size: w * 0.05),
                    text: 'Masraflar',
                    iconMargin: EdgeInsets.only(bottom: h * 0.005),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics:
                    const BouncingScrollPhysics(),                 children: [
                  _buildPaymentsTab(),
                  const AdvancesTab(),
                  const ExpensesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildPaymentsTab() {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final theme = Theme.of(context);

    final totalUnpaidDays = _controller.calculateTotalUnpaidDays(
      _employees,
      _unpaidDays,
    );
    final currentMonth = DateFormat('MMMM', 'tr_TR').format(DateTime.now());

    return _isLoading
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : _employees.isEmpty
        ? const AllPaidState()
        : SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h * 0.005),
                  PaymentBentoSummary(
                    currentMonth: currentMonth,
                    monthlyPaidAmount: _monthlyPaidAmount,
                    employeeCount: _employees.length,
                    totalUnpaidDays: totalUnpaidDays,
                  ),
                  SizedBox(height: h * 0.02),
                  _buildSearchBar(theme),
                  SizedBox(height: h * 0.02),
                  Expanded(
                    child: _filteredEmployees.isEmpty
                        ? const NoSearchResults()
                        : ListView.builder(
                            padding: EdgeInsets.only(bottom: h * 0.02),
                            itemCount: _filteredEmployees.length,
                            itemExtent: null,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior
                                    .onDrag,                             itemBuilder: (context, index) {
                              final emp = _filteredEmployees[index];
                              final unpaidDays = _unpaidDays[emp.id]!;
                              final score = _unpaidScores[emp.id] ?? 0;
                              return PaymentTransactionTile(
                                employee: emp,
                                unpaidDays: unpaidDays,
                                score: score,
                                onTap: () => _showPaymentDialog(emp),
                                primaryColor: primaryColor,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget? _buildFloatingActionButton() {
    return null;
  }

  Widget _buildSearchBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return TextField(
      controller: _searchController,
      onChanged: _filterEmployees,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: 'Çalışan ara...',
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
                  _filterEmployees('');
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
