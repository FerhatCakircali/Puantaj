import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../../models/expense.dart';
import '../../../../../utils/currency_input_formatter.dart';
import '../constants/expense_dialog_constants.dart';
import '../helpers/expense_category_helper.dart';
import '../helpers/expense_validator.dart';

final _validator = ExpenseFormValidator();

/// Masraf form field'ları widget'ı
///
/// Tüm form alanlarını içerir (tür, kategori, tutar, tarih, açıklama).
class ExpenseFormFields extends StatelessWidget {
  final TextEditingController expenseTypeController;
  final TextEditingController amountController;
  final TextEditingController descriptionController;
  final ExpenseCategory selectedCategory;
  final DateTime selectedDate;
  final ValueChanged<ExpenseCategory> onCategoryChanged;
  final VoidCallback onDateTap;

  const ExpenseFormFields({
    super.key,
    required this.expenseTypeController,
    required this.amountController,
    required this.descriptionController,
    required this.selectedCategory,
    required this.selectedDate,
    required this.onCategoryChanged,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final w = size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExpenseTypeField(theme, w),
        SizedBox(height: w * 0.04),
        _buildCategoryField(theme, w),
        SizedBox(height: w * 0.04),
        _buildAmountField(theme, w),
        SizedBox(height: w * 0.04),
        _buildDateField(theme, w),
        SizedBox(height: w * 0.04),
        _buildDescriptionField(theme, w),
      ],
    );
  }

  Widget _buildExpenseTypeField(ThemeData theme, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ExpenseDialogConstants.expenseTypeLabel,
          style: TextStyle(
            fontSize: w * 0.035,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: w * 0.02),
        TextFormField(
          controller: expenseTypeController,
          decoration: InputDecoration(
            hintText: ExpenseDialogConstants.expenseTypeHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ExpenseDialogConstants.borderRadius,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: w * 0.04,
              vertical: w * 0.035,
            ),
          ),
          validator: _validator.validateExpenseType,
        ),
      ],
    );
  }

  Widget _buildCategoryField(ThemeData theme, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ExpenseDialogConstants.categoryLabel,
          style: TextStyle(
            fontSize: w * 0.035,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: w * 0.02),
        DropdownButtonFormField<ExpenseCategory>(
          value: selectedCategory,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ExpenseDialogConstants.borderRadius,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: w * 0.04,
              vertical: w * 0.035,
            ),
          ),
          items: ExpenseCategory.values.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(ExpenseCategoryHelper.getCategoryName(category)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onCategoryChanged(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildAmountField(ThemeData theme, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ExpenseDialogConstants.amountLabel,
          style: TextStyle(
            fontSize: w * 0.035,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: w * 0.02),
        TextFormField(
          controller: amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(),
          ],
          decoration: InputDecoration(
            hintText: ExpenseDialogConstants.amountHint,
            prefixText: '₺ ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ExpenseDialogConstants.borderRadius,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: w * 0.04,
              vertical: w * 0.035,
            ),
          ),
          validator: _validator.validateAmountField,
        ),
      ],
    );
  }

  Widget _buildDateField(ThemeData theme, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ExpenseDialogConstants.dateLabel,
          style: TextStyle(
            fontSize: w * 0.035,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: w * 0.02),
        InkWell(
          onTap: onDateTap,
          borderRadius: BorderRadius.circular(
            ExpenseDialogConstants.borderRadius,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.04,
              vertical: w * 0.035,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(
                ExpenseDialogConstants.borderRadius,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey.shade600),
                SizedBox(width: w * 0.03),
                Text(
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(selectedDate),
                  style: TextStyle(
                    fontSize: w * 0.04,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(ThemeData theme, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ExpenseDialogConstants.descriptionLabel,
          style: TextStyle(
            fontSize: w * 0.035,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: w * 0.02),
        TextFormField(
          controller: descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: ExpenseDialogConstants.descriptionHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ExpenseDialogConstants.borderRadius,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: w * 0.04,
              vertical: w * 0.035,
            ),
          ),
        ),
      ],
    );
  }
}
