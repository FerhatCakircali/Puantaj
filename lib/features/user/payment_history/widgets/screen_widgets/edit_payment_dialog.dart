import 'package:flutter/material.dart';

import 'edit_payment/index.dart';

/// Ödeme düzenleme dialog'u
/// Ödeme bilgilerini güncelleme ve silme işlemlerini yönetir
class EditPaymentDialog extends StatefulWidget {
  final int paymentId;
  final int workerId;
  final String workerName;
  final int currentFullDays;
  final int currentHalfDays;
  final double currentAmount;
  final DateTime paymentDate;
  final DateTime displayTime;
  final int maxFullDays;
  final int maxHalfDays;
  final Future<void> Function(int, int, int, double) onUpdate;
  final VoidCallback onDelete;

  const EditPaymentDialog({
    super.key,
    required this.paymentId,
    required this.workerId,
    required this.workerName,
    required this.currentFullDays,
    required this.currentHalfDays,
    required this.currentAmount,
    required this.paymentDate,
    required this.displayTime,
    required this.maxFullDays,
    required this.maxHalfDays,
    required this.onUpdate,
    required this.onDelete,
  });

  /// Dialog'u göster
  static Future<void> show(
    BuildContext context, {
    required int paymentId,
    required int workerId,
    required String workerName,
    required int currentFullDays,
    required int currentHalfDays,
    required double currentAmount,
    required DateTime paymentDate,
    required DateTime displayTime,
    required int maxFullDays,
    required int maxHalfDays,
    required Future<void> Function(int, int, int, double) onUpdate,
    required VoidCallback onDelete,
  }) {
    return showDialog(
      context: context,
      builder: (context) => EditPaymentDialog(
        paymentId: paymentId,
        workerId: workerId,
        workerName: workerName,
        currentFullDays: currentFullDays,
        currentHalfDays: currentHalfDays,
        currentAmount: currentAmount,
        paymentDate: paymentDate,
        displayTime: displayTime,
        maxFullDays: maxFullDays,
        maxHalfDays: maxHalfDays,
        onUpdate: onUpdate,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<EditPaymentDialog> createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends State<EditPaymentDialog> {
  late TextEditingController _fullDaysController;
  late TextEditingController _halfDaysController;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _fullDaysController = TextEditingController(
      text: widget.currentFullDays.toString(),
    );
    _halfDaysController = TextEditingController(
      text: widget.currentHalfDays.toString(),
    );
    _amountController = TextEditingController(
      text: EditPaymentDialogHelpers.formatAmountForDisplay(
        widget.currentAmount.toInt(),
      ),
    );
  }

  @override
  void dispose() {
    _fullDaysController.dispose();
    _halfDaysController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EditPaymentDialogHeader(
              workerName: widget.workerName,
              isDark: isDark,
              onClose: () => Navigator.pop(context),
            ),
            _buildDivider(isDark),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: EditPaymentDialogForm(
                  fullDaysController: _fullDaysController,
                  halfDaysController: _halfDaysController,
                  amountController: _amountController,
                  maxFullDays: widget.maxFullDays,
                  maxHalfDays: widget.maxHalfDays,
                  paymentDate: widget.paymentDate,
                  displayTime: widget.displayTime,
                  isDark: isDark,
                ),
              ),
            ),
            EditPaymentDialogActions(
              onCancel: () => Navigator.pop(context),
              onDelete: widget.onDelete,
              onUpdate: _handleUpdate,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.grey.shade200,
    );
  }

  void _handleUpdate() {
    final fullDays =
        int.tryParse(_fullDaysController.text) ?? widget.currentFullDays;
    final halfDays =
        int.tryParse(_halfDaysController.text) ?? widget.currentHalfDays;
    final amount =
        double.tryParse(_amountController.text.replaceAll('.', '')) ??
        widget.currentAmount;

    widget.onUpdate(widget.paymentId, fullDays, halfDays, amount);
  }
}
