import 'package:flutter/material.dart';
import '../../../../widgets/common/themed_text_field.dart';
import '../../payment_history/widgets/screen_widgets/index.dart';
import '../controllers/payment_history_controller.dart';
import '../widgets/date_range_selector.dart';
import '../widgets/payment_history_actions.dart';

/// Kullanıcı (Yönetici) Ödeme Geçmişi Ekranı
///
/// Ödeme kayıtlarını listeler, düzenler ve siler.
/// AGENTS.md kurallarına uygun olarak modüler yapıda tasarlanmıştır.
class UserPaymentHistoryScreen extends StatefulWidget {
  const UserPaymentHistoryScreen({super.key});

  @override
  State<UserPaymentHistoryScreen> createState() =>
      _UserPaymentHistoryScreenState();
}

class _UserPaymentHistoryScreenState extends State<UserPaymentHistoryScreen> {
  final _controller = PaymentHistoryController();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _filteredPayments = [];

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPayments();
    _searchController.addListener(_filterPayments);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final payments = await _controller.loadPayments(
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) return;
      setState(() {
        _payments = payments;
        _filteredPayments = payments;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _filterPayments() {
    setState(() {
      _filteredPayments = _controller.filterPayments(
        _payments,
        _searchController.text,
      );
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await PaymentHistoryActions.selectDateRange(
      context,
      _startDate,
      _endDate,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadPayments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryColor = Color(0xFF4338CA);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            DateRangeSelector(
              startDate: _startDate,
              endDate: _endDate,
              onTap: _selectDateRange,
            ),
            _buildSearchField(w, h),
            Expanded(child: _buildContent(w, h, isDark, primaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(double w, double h) {
    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.06, h * 0.02, w * 0.06, h * 0.015),
      child: ThemedTextField(
        controller: _searchController,
        labelText: 'Çalışan ara...',
        prefixIcon: Icons.search,
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              )
            : null,
      ),
    );
  }

  Widget _buildContent(double w, double h, bool isDark, Color primaryColor) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (_filteredPayments.isEmpty) {
      return PaymentHistoryEmptyState(
        isSearching: _searchController.text.isNotEmpty,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPayments,
      color: primaryColor,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(w * 0.06, 0, w * 0.06, h * 0.1),
        itemCount: _filteredPayments.length,
        separatorBuilder: (context, index) => SizedBox(height: h * 0.015),
        itemBuilder: (context, index) {
          final payment = _filteredPayments[index];
          return PaymentHistoryCard(
            payment: payment,
            onTap: () => _handlePaymentTap(payment),
          );
        },
      ),
    );
  }

  void _handlePaymentTap(Map<String, dynamic> payment) async {
    final details = _controller.parsePaymentDetails(payment);

    debugPrint(
      '📝 Ödeme düzenleme açılıyor: paymentId=${details.id}, workerId=${details.workerId}',
    );

    final unpaidDays = await _controller.getUnpaidDaysExcludingPayment(
      details.workerId,
      details.id,
    );
    final maxFullDays = unpaidDays['fullDays'] ?? 0;
    final maxHalfDays = unpaidDays['halfDays'] ?? 0;

    if (!mounted) return;

    EditPaymentDialog.show(
      context,
      paymentId: details.id,
      workerId: details.workerId,
      workerName: details.workerName,
      currentFullDays: details.fullDays,
      currentHalfDays: details.halfDays,
      currentAmount: details.amount,
      paymentDate: details.paymentDate,
      displayTime: details.displayTime,
      maxFullDays: maxFullDays,
      maxHalfDays: maxHalfDays,
      onUpdate: _updatePayment,
      onDelete: () => _confirmDelete(details.id),
    );
  }

  Future<void> _updatePayment(
    int paymentId,
    int fullDays,
    int halfDays,
    double amount,
  ) async {
    Navigator.pop(context);

    try {
      final success = await _controller.updatePayment(
        paymentId: paymentId,
        fullDays: fullDays,
        halfDays: halfDays,
        amount: amount,
      );

      if (success && mounted) {
        PaymentHistoryActions.showSuccessMessage(
          context,
          'Ödeme güncellendi ve çalışana bildirim gönderildi',
        );
        _loadPayments();
      }
    } catch (e) {
      if (mounted) {
        PaymentHistoryActions.showErrorMessage(context, e.toString());
      }
    }
  }

  void _confirmDelete(int paymentId) {
    Navigator.pop(context);

    DeletePaymentDialog.show(
      context,
      onConfirm: () => _deletePayment(paymentId),
    );
  }

  Future<void> _deletePayment(int paymentId) async {
    Navigator.pop(context);

    try {
      final success = await _controller.deletePayment(paymentId);

      if (success && mounted) {
        PaymentHistoryActions.showSuccessMessage(
          context,
          'Ödeme silindi ve çalışana bildirim gönderildi',
        );
        _loadPayments();
      }
    } catch (e) {
      if (mounted) {
        PaymentHistoryActions.showErrorMessage(context, e.toString());
      }
    }
  }
}
