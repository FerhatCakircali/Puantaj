import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../models/employee.dart';
import '../../../../../../utils/formatters/thousands_separator_formatter.dart';
import '../../../../../../utils/currency_formatter.dart';
import 'payment_auto_calculate_toggle.dart';
import 'payment_available_days_card.dart';
import 'payment_input_field.dart';
import '../controllers/payment_dialog_controller.dart';
import 'payment_dialog_header.dart';
import 'payment_dialog_actions.dart';
import '../../../../../../services/advance_service.dart';
import '../../../../../../models/advance.dart';

/// Ödeme dialog widget'ı
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
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
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
  final _advanceService = AdvanceService();
  final _fullDaysController = TextEditingController();
  final _halfDaysController = TextEditingController();
  final _amountController = TextEditingController();
  final _dailyRateController = TextEditingController();
  late final ScrollController _scrollController;

  final _dailyRateKey = GlobalKey();
  final _fullDaysKey = GlobalKey();
  final _halfDaysKey = GlobalKey();
  final _amountKey = GlobalKey();

  late final FocusNode _dailyRateFocus;
  late final FocusNode _fullDaysFocus;
  late final FocusNode _halfDaysFocus;
  late final FocusNode _amountFocus;

  bool _isLoading = true;
  bool _autoCalculate = false;
  int _availableFullDays = 0;
  int _availableHalfDays = 0;

  // Avans değişkenleri
  List<Advance> _pendingAdvances = [];
  bool _deductAdvances = false;
  double _totalPendingAdvances = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _dailyRateFocus = FocusNode();
    _fullDaysFocus = FocusNode();
    _halfDaysFocus = FocusNode();
    _amountFocus = FocusNode();

    _dailyRateFocus.addListener(() {
      if (_dailyRateFocus.hasFocus) _ensureVisible(_dailyRateKey);
    });
    _fullDaysFocus.addListener(() {
      if (_fullDaysFocus.hasFocus) _ensureVisible(_fullDaysKey);
    });
    _halfDaysFocus.addListener(() {
      if (_halfDaysFocus.hasFocus) _ensureVisible(_halfDaysKey);
    });
    _amountFocus.addListener(() {
      if (_amountFocus.hasFocus) _ensureVisible(_amountKey);
    });

    _loadUnpaidDays();
    _fullDaysController.addListener(_calculateAmount);
    _halfDaysController.addListener(_calculateAmount);
    _dailyRateController.addListener(_calculateAmount);
  }

  @override
  void dispose() {
    _fullDaysController.removeListener(_calculateAmount);
    _halfDaysController.removeListener(_calculateAmount);
    _dailyRateController.removeListener(_calculateAmount);

    _fullDaysController.dispose();
    _halfDaysController.dispose();
    _amountController.dispose();
    _dailyRateController.dispose();
    _scrollController.dispose();
    _dailyRateFocus.dispose();
    _fullDaysFocus.dispose();
    _halfDaysFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _ensureVisible(GlobalKey key) async {
    await Future.delayed(const Duration(milliseconds: 60));
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: 0.2,
    );
  }

  Future<void> _loadUnpaidDays() async {
    setState(() => _isLoading = true);
    final unpaidDays = await _controller.loadUnpaidDays(widget.employee.id);

    // Bekleyen avansları yükle
    final pendingAdvances = await _advanceService.getWorkerAdvances(
      widget.employee.id,
    );
    final pending = pendingAdvances.where((a) => !a.isDeducted).toList();
    final totalPending = pending.fold<double>(0, (sum, a) => sum + a.amount);

    setState(() {
      _availableFullDays = unpaidDays['fullDays'] ?? 0;
      _availableHalfDays = unpaidDays['halfDays'] ?? 0;
      _pendingAdvances = pending;
      _totalPendingAdvances = totalPending;
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
    var amount = double.tryParse(amountText) ?? 0.0;

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

    // Avans düşme kontrolü
    if (_deductAdvances && _totalPendingAdvances > 0) {
      if (amount < _totalPendingAdvances) {
        _showErrorDialog(
          'Ödeme tutarı (${CurrencyFormatter.formatWithSymbol(amount)}) bekleyen avans tutarından (${CurrencyFormatter.formatWithSymbol(_totalPendingAdvances)}) az olamaz.',
        );
        return;
      }
      // Avansı düş
      amount -= _totalPendingAdvances;
    }

    setState(() => _isLoading = true);

    try {
      // Ödeme yap
      final paymentId = await _controller.makePayment(
        employee: widget.employee,
        fullDays: fullDays,
        halfDays: halfDays,
        amount: amount,
      );

      // Avansları düşülmüş olarak işaretle
      if (_deductAdvances && _pendingAdvances.isNotEmpty && paymentId != null) {
        for (final advance in _pendingAdvances) {
          await _advanceService.markAsDeducted(advance.id!, paymentId);
        }
      }

      if (mounted) {
        String message = 'Ödeme başarıyla kaydedildi';
        if (_deductAdvances && _totalPendingAdvances > 0) {
          message +=
              '\n${CurrencyFormatter.formatWithSymbol(_totalPendingAdvances)} avans düşüldü';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context);
          widget.onPaymentComplete();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Ödeme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ödeme kaydedilirken bir hata oluştu: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0A0E1A) : Colors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDragHandle(isDark),
                      const SizedBox(height: 16),
                      RepaintBoundary(
                        child: PaymentDialogHeader(
                          employee: widget.employee,
                          onClose: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAvailableDaysCard(),
                      const SizedBox(height: 12),
                      Expanded(child: _buildForm(isDark)),
                      RepaintBoundary(
                        child: PaymentDialogActions(
                          onPayment: _makePayment,
                          onCancel: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
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
      controller: _scrollController,
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
            Container(
              key: _dailyRateKey,
              child: PaymentInputField(
                icon: Icons.currency_lira,
                label: 'Günlük Ücret',
                hint: '0',
                controller: _dailyRateController,
                focusNode: _dailyRateFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_availableFullDays > 0) ...[
            Container(
              key: _fullDaysKey,
              child: PaymentInputField(
                icon: Icons.wb_sunny_outlined,
                label: 'Tam Gün Sayısı',
                hint: 'Maks: $_availableFullDays',
                controller: _fullDaysController,
                focusNode: _fullDaysFocus,
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
            ),
            const SizedBox(height: 16),
          ],
          if (_availableHalfDays > 0) ...[
            Container(
              key: _halfDaysKey,
              child: PaymentInputField(
                icon: Icons.wb_twilight_outlined,
                label: 'Yarım Gün Sayısı',
                hint: 'Maks: $_availableHalfDays',
                controller: _halfDaysController,
                focusNode: _halfDaysFocus,
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
            ),
            const SizedBox(height: 16),
          ],
          if ((int.tryParse(_fullDaysController.text) ?? 0) > 0 ||
              (int.tryParse(_halfDaysController.text) ?? 0) > 0) ...[
            Container(
              key: _amountKey,
              child: PaymentInputField(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Ödenecek Miktar',
                hint: '0',
                controller: _amountController,
                focusNode: _amountFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Avans bölümü
            if (_pendingAdvances.isNotEmpty) _buildAdvanceSection(isDark),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAdvanceSection(bool isDark) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _deductAdvances
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Bekleyen Avanslar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_pendingAdvances.length} adet bekleyen avans',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toplam: ${CurrencyFormatter.formatWithSymbol(_totalPendingAdvances)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _deductAdvances,
            onChanged: (value) {
              setState(() {
                _deductAdvances = value ?? false;
              });
            },
            title: Text(
              'Avansları ödemeden düş',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            subtitle: _deductAdvances
                ? Text(
                    'Ödenecek tutar: ${CurrencyFormatter.formatWithSymbol(_getPaymentAmount() - _totalPendingAdvances)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  double _getPaymentAmount() {
    final amountText = _amountController.text.replaceAll('.', '');
    return double.tryParse(amountText) ?? 0.0;
  }
}
