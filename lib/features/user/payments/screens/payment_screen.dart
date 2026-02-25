import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/employee.dart';
import '../../employees/widgets/employee_search_bar.dart';
import '../controllers/payment_controller.dart';
import '../widgets/payment_bento_summary.dart';
import '../widgets/payment_transaction_tile.dart';
import '../widgets/payment_empty_states.dart';
import '../dialogs/payment_dialog/widgets/payment_dialog.dart';

/// Ödeme yönetim ekranı
///
/// Çalışanların ödenmemiş günlerini listeler ve ödeme işlemlerini yönetir.
/// AGENTS.md kurallarına uygun olarak modüler yapıda tasarlanmıştır.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
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
    _loadData();
  }

  @override
  void dispose() {
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
      debugPrint('⚠️ Payment data yükleme hatası: $e');

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
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    final totalUnpaidDays = _controller.calculateTotalUnpaidDays(
      _employees,
      _unpaidDays,
    );
    final currentMonth = DateFormat('MMMM', 'tr_TR').format(DateTime.now());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _employees.isEmpty
          ? const AllPaidState()
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: h * 0.02),
                    PaymentBentoSummary(
                      currentMonth: currentMonth,
                      monthlyPaidAmount: _monthlyPaidAmount,
                      employeeCount: _employees.length,
                      totalUnpaidDays: totalUnpaidDays,
                    ),
                    SizedBox(height: h * 0.02),
                    EmployeeSearchBar(
                      controller: _searchController,
                      onChanged: _filterEmployees,
                      onClear: () {
                        _searchController.clear();
                        _filterEmployees('');
                      },
                    ),
                    SizedBox(height: h * 0.02),
                    Expanded(
                      child: _filteredEmployees.isEmpty
                          ? const NoSearchResults()
                          : ListView.builder(
                              padding: EdgeInsets.only(bottom: h * 0.02),
                              itemCount: _filteredEmployees.length,
                              itemBuilder: (context, index) {
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
            ),
    );
  }
}
