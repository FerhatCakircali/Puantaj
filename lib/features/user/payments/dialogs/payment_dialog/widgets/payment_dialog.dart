import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../models/employee.dart';
import '../../../../../../screens/constants/colors.dart';
import '../../../../../../utils/formatters/thousands_separator_formatter.dart';
import 'payment_auto_calculate_toggle.dart';
import 'payment_available_days_card.dart';
import 'payment_input_field.dart';
import '../controllers/payment_dialog_controller.dart';
import 'payment_dialog_header.dart';
import 'payment_dialog_actions.dart';

/// Ödeme dialog'u
///
/// Çalışana ödeme yapmak için kullanılır.
/// AGENTS.md kurallarına uygun olarak modüler yapıda tasarlanmıştır.
class PaymentDialog extends StatefulWidget {
  final Employee employee;
  final VoidCallback onPaymentComplete;

  const PaymentDialog({
    super.key,
    required this.employee,
    required this.onPaymentComplete,
  });

  static void show(
    BuildContext context, {
    required Employee employee,
    required VoidCallback onPaymentComplete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentDialog(
        employee: employee,
        onPaymentComplete: onPaymentComplete,
      ),
    );
  }

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _controller = PaymentDialogController();
  final _fullDaysController = TextEditingController();
  final _halfDaysController = TextEditingController();
  final _amountController = TextEditingController();
  final _dailyRateController = TextEditingController();

  bool _isLoading = true;
  bool _autoCalculate = false;
  int _availableFullDays = 0;
  int _availableHalfDays = 0;

  @override
  void initState() {
    super.initState();
    _loadUnpaidDays();
    _fullDaysController.addListener(_calculateAmount);
    _halfDaysController.addListener(_calculateAmount);
    _dailyRateController.addListener(_calculateAmount);
  }

  @override
  void dispose() {
    _fullDaysController.dispose();
    _halfDaysController.dispose();
    _amountController.dispose();
    _dailyRateController.dispose();
    super.dispose();
  }

  Future<void> _loadUnpaidDays() async {
    setState(() => _isLoading = true);
    final unpaidDays = await _controller.loadUnpaidDays(widget.employee.id);
    setState(() {
      _availableFullDays = unpaidDays['fullDays'] ?? 0;
      _availableHalfDays = unpaidDays['halfDays'] ?? 0;
      _isLoading = false;
    });
  }

  void _calculateAmount() {
    if (!_autoCalculate) return;

    final fullDays = int.tryParse(_fullDaysController.text) ?? 0;
    final halfDays = int.tryParse(_halfDaysController.text) ?? 0;
    final dailyRateText = _dailyRateController.text.replaceAll('.', '');
    final dailyRate = double.tryParse(dailyRateText) ?? 0.0;

    if (dailyRate > 0) {
      final totalAmount = _controller.calculateAmount(
        fullDays: fullDays,
        halfDays: halfDays,
        dailyRate: dailyRate,
      );
      final intAmount = totalAmount.toInt();
      final formatted = _controller.formatNumber(intAmount);
      _amountController.text = formatted;
    }
  }

  Future<void> _makePayment() async {
    final fullDays = int.tryParse(_fullDaysController.text) ?? 0;
    final halfDays = int.tryParse(_halfDaysController.text) ?? 0;
    final amountText = _amountController.text.replaceAll('.', '');
    final amount = double.tryParse(amountText) ?? 0.0;

    final validationError = _controller.validatePayment(
      fullDays: fullDays,
      halfDays: halfDays,
      amount: amount,
      availableFullDays: _availableFullDays,
      availableHalfDays: _availableHalfDays,
    );

    if (validationError != null) {
      _showErrorDialog(validationError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _controller.makePayment(
        employee: widget.employee,
        fullDays: fullDays,
        halfDays: halfDays,
        amount: amount,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onPaymentComplete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ödeme başarıyla kaydedildi'),
            backgroundColor: primaryIndigo,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Ödeme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _isLoading = false);

      if (mounted) {
        _showErrorDialog('Ödeme kaydedilirken bir hata oluştu: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0A0E1A) : Colors.white;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryIndigo))
          : Column(
              children: [
                _buildDragHandle(isDark),
                const SizedBox(height: 16),
                PaymentDialogHeader(
                  employee: widget.employee,
                  onClose: () => Navigator.pop(context),
                ),
                const SizedBox(height: 12),
                _buildAvailableDaysCard(),
                const SizedBox(height: 12),
                Expanded(child: _buildForm(isDark)),
                PaymentDialogActions(
                  onPayment: _makePayment,
                  onCancel: () => Navigator.pop(context),
                ),
              ],
            ),
    );
  }

  Widget _buildDragHandle(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildAvailableDaysCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: PaymentAvailableDaysCard(
        fullDays: _availableFullDays,
        halfDays: _availableHalfDays,
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          PaymentAutoCalculateToggle(
            isEnabled: _autoCalculate,
            onChanged: (value) {
              setState(() {
                _autoCalculate = value;
                if (!_autoCalculate) {
                  _dailyRateController.clear();
                  _amountController.clear();
                } else {
                  _calculateAmount();
                }
              });
            },
          ),
          const SizedBox(height: 16),
          if (_autoCalculate) ...[
            PaymentInputField(
              icon: Icons.currency_lira,
              label: 'Günlük Ücret',
              hint: '0',
              controller: _dailyRateController,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorInputFormatter(),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (_availableFullDays > 0) ...[
            PaymentInputField(
              icon: Icons.wb_sunny_outlined,
              label: 'Tam Gün Sayısı',
              hint: 'Maks: $_availableFullDays',
              controller: _fullDaysController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                final val = int.tryParse(value) ?? 0;
                if (val > _availableFullDays) {
                  _fullDaysController.text = _availableFullDays.toString();
                  _fullDaysController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _fullDaysController.text.length),
                  );
                }
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
          ],
          if (_availableHalfDays > 0) ...[
            PaymentInputField(
              icon: Icons.wb_twilight_outlined,
              label: 'Yarım Gün Sayısı',
              hint: 'Maks: $_availableHalfDays',
              controller: _halfDaysController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                final val = int.tryParse(value) ?? 0;
                if (val > _availableHalfDays) {
                  _halfDaysController.text = _availableHalfDays.toString();
                  _halfDaysController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _halfDaysController.text.length),
                  );
                }
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
          ],
          if ((int.tryParse(_fullDaysController.text) ?? 0) > 0 ||
              (int.tryParse(_halfDaysController.text) ?? 0) > 0)
            PaymentInputField(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Ödenecek Miktar',
              hint: '0',
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorInputFormatter(),
              ],
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
