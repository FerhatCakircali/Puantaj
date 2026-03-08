import 'package:flutter/material.dart';
import '../../../../models/expense.dart';
import 'base_expense_dialog.dart';
import 'helpers/expense_snackbar_helper.dart';

/// Masraf düzenleme dialog'u
///
/// Mevcut masraf kaydını günceller.
class EditExpenseDialog extends BaseExpenseDialog {
  final Expense expense;
  final VoidCallback onExpenseUpdated;

  const EditExpenseDialog({
    super.key,
    required this.expense,
    required this.onExpenseUpdated,
  });

  /// Dialog'u gösterir
  static Future<void> show(
    BuildContext context, {
    required Expense expense,
    required VoidCallback onExpenseUpdated,
  }) {
    return showDialog(
      context: context,
      builder: (context) => EditExpenseDialog(
        expense: expense,
        onExpenseUpdated: onExpenseUpdated,
      ),
    );
  }

  @override
  State<EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState
    extends BaseExpenseDialogState<EditExpenseDialog> {
  @override
  void initializeControllers() {
    expenseTypeController = TextEditingController(
      text: widget.expense.expenseType,
    );
    amountController = TextEditingController(
      text: widget.expense.amount.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      ),
    );
    descriptionController = TextEditingController(
      text: widget.expense.description ?? '',
    );
    selectedCategory = widget.expense.category;
    selectedDate = widget.expense.expenseDate;
  }

  @override
  IconData get headerIcon => Icons.edit;

  @override
  String get headerTitle => 'Masraf Düzenle';

  @override
  String get submitButtonText => 'Güncelle';

  @override
  Future<void> onSubmit() async {
    final updatedExpense = widget.expense.copyWith(
      expenseType: expenseTypeController.text.trim(),
      category: selectedCategory,
      amount: createExpense().amount,
      expenseDate: selectedDate,
      description: descriptionController.text.trim(),
    );

    await controller.updateExpense(updatedExpense);

    if (!mounted) return;

    widget.onExpenseUpdated();

    ExpenseSnackbarHelper.showSuccess(context, 'Masraf güncellendi');
  }
}
