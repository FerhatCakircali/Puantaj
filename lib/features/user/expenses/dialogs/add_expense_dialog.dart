import 'package:flutter/material.dart';
import 'base_expense_dialog.dart';
import 'helpers/expense_snackbar_helper.dart';

/// Masraf ekleme dialog'u
///
/// Yeni masraf kaydı oluşturur.
class AddExpenseDialog extends BaseExpenseDialog {
  final VoidCallback onExpenseAdded;

  const AddExpenseDialog({super.key, required this.onExpenseAdded});

  /// Dialog'u gösterir
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onExpenseAdded,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AddExpenseDialog(onExpenseAdded: onExpenseAdded),
    );
  }

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends BaseExpenseDialogState<AddExpenseDialog> {
  @override
  IconData get headerIcon => Icons.receipt_long;

  @override
  String get headerTitle => 'Masraf Ekle';

  @override
  String get submitButtonText => 'Kaydet';

  @override
  Future<void> onSubmit() async {
    final expense = createExpense();

    await controller.addExpense(expense);

    if (!mounted) return;

    widget.onExpenseAdded();

    ExpenseSnackbarHelper.showSuccess(
      context,
      '${expense.expenseType} masrafı eklendi',
    );
  }
}
