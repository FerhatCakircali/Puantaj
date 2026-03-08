import 'package:flutter/material.dart';
import '../../../../../../models/employee.dart';
import '../../../../../../models/advance.dart';
import '../../../../../../services/advance_service.dart';
import '../../../../../../shared/widgets/dialog/dialog_handle_bar.dart';
import '../controllers/payment_dialog_controller.dart';
import '../handlers/payment_submission_handler.dart';
import '../helpers/payment_dialog_helper.dart';
import '../helpers/payment_validation_helper.dart';
import '../helpers/payment_focus_helper.dart';
import 'payment_dialog_header.dart';
import 'payment_dialog_actions.dart';
import 'payment_available_days_card.dart';
import 'payment_auto_calculate_toggle.dart';
import 'payment_form_fields.dart';
import 'payment_advance_section.dart';
import '../../../../../../core/di/service_locator.dart';

/// Ödeme dialog widget'ı
///
/// Çalışan ödemelerini kaydetmek için kullanılır
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
  late final PaymentSubmissionHandler _submissionHandler;
  late final PaymentFocusHelper _focusHelper;
  late final AdvanceService _advanceService;
  final _fullDaysController = TextEditingController();
  final _halfDaysController = TextEditingController();
  final _amountController = TextEditingController();
  final _dailyRateController = TextEditingController();
  late final ScrollController _scrollController;

  final _dailyRateKey = GlobalKey();
  final _fullDaysKey = GlobalKey();
  final _halfDaysKey = GlobalKey();
  final _amountKey = GlobalKey();

  bool _isLoading = true;
  bool _autoCalculate = false;
  int _availableFullDays = 0;
  int _availableHalfDays = 0;

  List<Advance> _pendingAdvances = [];
  bool _deductAdvances = false;
  double _totalPendingAdvances = 0;

  @override
  void initState() {
    super.initState();
    _advanceService = getIt<AdvanceService>();
    _submissionHandler = PaymentSubmissionHandler(controller: _controller);
    _scrollController = ScrollController();
    _initializeFocusHelper();
    _setupCalculationListeners();
    _loadUnpaidDays();
  }

  void _initializeFocusHelper() {
    _focusHelper = PaymentFocusHelper(
      scrollController: _scrollController,
      dailyRateFocus: FocusNode(),
      fullDaysFocus: FocusNode(),
      halfDaysFocus: FocusNode(),
      amountFocus: FocusNode(),
    );

    _focusHelper.setupListeners(
      dailyRateKey: _dailyRateKey,
      fullDaysKey: _fullDaysKey,
      halfDaysKey: _halfDaysKey,
      amountKey: _amountKey,
    );
  }

  void _setupCalculationListeners() {
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
    _focusHelper.dispose();
    super.dispose();
  }

  Future<void> _loadUnpaidDays() async {
    setState(() => _isLoading = true);
    final unpaidDays = await _controller.loadUnpaidDays(widget.employee.id);

    final pendingAdvances = await _advanceService.getWorkerAdvances(
      widget.employee.id,
    );
    final pending = pendingAdvances.where((a) => !a.isDeducted).toList();
    final totalPending = pending.fold<double>(0, (sum, a) => sum + a.amount);

    if (mounted) {
      setState(() {
        _availableFullDays = unpaidDays['fullDays'] ?? 0;
        _availableHalfDays = unpaidDays['halfDays'] ?? 0;
        _pendingAdvances = pending;
        _totalPendingAdvances = totalPending;
        _isLoading = false;
      });
    }
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
    final amount = PaymentValidationHelper.parseAmount(_amountController.text);

    setState(() => _isLoading = true);

    final result = await _submissionHandler.submitPayment(
      employee: widget.employee,
      fullDays: fullDays,
      halfDays: halfDays,
      amount: amount,
      availableFullDays: _availableFullDays,
      availableHalfDays: _availableHalfDays,
      deductAdvances: _deductAdvances,
      pendingAdvances: _pendingAdvances,
      totalPendingAdvances: _totalPendingAdvances,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      PaymentDialogHelper.showSuccessAndClose(
        context,
        message: result.getSuccessMessage(),
        onComplete: widget.onPaymentComplete,
      );
    } else {
      setState(() => _isLoading = false);
      PaymentDialogHelper.showErrorDialog(context, result.errorMessage!);
    }
  }

  void _handleFullDaysChanged(String value) {
    PaymentValidationHelper.validateAndCorrectFullDays(
      value,
      _availableFullDays,
      _fullDaysController,
    );
    setState(() {});
  }

  void _handleHalfDaysChanged(String value) {
    PaymentValidationHelper.validateAndCorrectHalfDays(
      value,
      _availableHalfDays,
      _halfDaysController,
    );
    setState(() {});
  }

  double _getPaymentAmount() {
    return PaymentValidationHelper.parseAmount(_amountController.text);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                      color: colorScheme.primary,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DialogHandleBar(
                        screenWidth: screenWidth,
                        colorScheme: colorScheme,
                      ),
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
                      Expanded(child: _buildForm()),
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

  Widget _buildAvailableDaysCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: PaymentAvailableDaysCard(
        fullDays: _availableFullDays,
        halfDays: _availableHalfDays,
      ),
    );
  }

  Widget _buildForm() {
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
          PaymentFormFields(
            autoCalculate: _autoCalculate,
            availableFullDays: _availableFullDays,
            availableHalfDays: _availableHalfDays,
            dailyRateController: _dailyRateController,
            fullDaysController: _fullDaysController,
            halfDaysController: _halfDaysController,
            amountController: _amountController,
            dailyRateFocus: _focusHelper.dailyRateFocus,
            fullDaysFocus: _focusHelper.fullDaysFocus,
            halfDaysFocus: _focusHelper.halfDaysFocus,
            amountFocus: _focusHelper.amountFocus,
            dailyRateKey: _dailyRateKey,
            fullDaysKey: _fullDaysKey,
            halfDaysKey: _halfDaysKey,
            amountKey: _amountKey,
            onFullDaysChanged: _handleFullDaysChanged,
            onHalfDaysChanged: _handleHalfDaysChanged,
          ),
          PaymentAdvanceSection(
            pendingAdvances: _pendingAdvances,
            totalPendingAdvances: _totalPendingAdvances,
            deductAdvances: _deductAdvances,
            onDeductChanged: (value) => setState(() => _deductAdvances = value),
            paymentAmount: _getPaymentAmount(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
