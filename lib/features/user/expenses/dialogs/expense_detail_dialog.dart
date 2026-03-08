import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/expense.dart';
import '../../../../utils/currency_formatter.dart';
import 'edit_expense_dialog.dart';
import 'expense_detail_dialog/widgets/expense_detail_header.dart';
import 'expense_detail_dialog/widgets/expense_info_row.dart';
import 'expense_detail_dialog/widgets/expense_action_buttons.dart';
import 'expense_detail_dialog/helpers/expense_category_helper.dart';
import 'expense_detail_dialog/handlers/expense_delete_handler.dart';

/// Masraf detay dialog'u
class ExpenseDetailDialog extends StatelessWidget {
  final Expense expense;
  final VoidCallback onExpenseUpdated;

  const ExpenseDetailDialog({
    super.key,
    required this.expense,
    required this.onExpenseUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required Expense expense,
    required VoidCallback onExpenseUpdated,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ExpenseDetailDialog(
        expense: expense,
        onExpenseUpdated: onExpenseUpdated,
      ),
    );
  }

  void _editExpense(BuildContext context) {
    Navigator.pop(context);
    EditExpenseDialog.show(
      context,
      expense: expense,
      onExpenseUpdated: onExpenseUpdated,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final categoryColor = ExpenseCategoryHelper.getCategoryColor(
      expense.category,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(w * 0.06),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExpenseDetailHeader(
              icon: ExpenseCategoryHelper.getCategoryIcon(expense.category),
              color: categoryColor,
              width: w,
            ),
            SizedBox(height: w * 0.06),
            ExpenseInfoRow(
              icon: Icons.receipt_long,
              label: 'Masraf Türü',
              value: expense.expenseType,
              width: w,
            ),
            SizedBox(height: w * 0.04),
            ExpenseInfoRow(
              icon: Icons.category,
              label: 'Kategori',
              value: ExpenseCategoryHelper.getCategoryName(expense.category),
              width: w,
              valueColor: categoryColor,
            ),
            SizedBox(height: w * 0.04),
            ExpenseInfoRow(
              icon: Icons.currency_lira,
              label: 'Tutar',
              value: CurrencyFormatter.formatWithSymbol(expense.amount),
              width: w,
              valueColor: const Color(0xFF4338CA),
              valueBold: true,
            ),
            SizedBox(height: w * 0.04),
            ExpenseInfoRow(
              icon: Icons.calendar_today,
              label: 'Tarih',
              value: DateFormat(
                'dd MMMM yyyy',
                'tr_TR',
              ).format(expense.expenseDate),
              width: w,
            ),
            SizedBox(height: w * 0.04),
            if (expense.description != null &&
                expense.description!.isNotEmpty) ...[
              ExpenseInfoRow(
                icon: Icons.description,
                label: 'Açıklama',
                value: expense.description!,
                width: w,
                multiline: true,
              ),
              SizedBox(height: w * 0.04),
            ],
            if (expense.receiptUrl != null &&
                expense.receiptUrl!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.receipt,
                    size: w * 0.05,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: w * 0.02),
                  Text(
                    'Fatura mevcut',
                    style: TextStyle(
                      fontSize: w * 0.035,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: w * 0.04),
            ],
            SizedBox(height: w * 0.02),
            ExpenseActionButtons(
              onDelete: () => ExpenseDeleteHandler.deleteExpense(
                context,
                expense: expense,
                onDeleted: onExpenseUpdated,
              ),
              onEdit: () => _editExpense(context),
              width: w,
            ),
          ],
        ),
      ),
    );
  }
}
