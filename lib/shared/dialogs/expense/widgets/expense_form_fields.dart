import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../models/expense.dart';
import '../../../../utils/currency_input_formatter.dart';
import '../constants/expense_dialog_constants.dart';
import '../helpers/expense_category_helper.dart';

/// Masraf form alanları widget'ı
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
    final w = MediaQuery.sizeOf(context).width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, 'Masraf Türü', w),
        SizedBox(height: w * 0.02),
        _buildExpenseTypeField(w),
        SizedBox(height: w * 0.04),

        _buildLabel(context, 'Kategori', w),
        SizedBox(height: w * 0.02),
        _buildCategoryDropdown(w),
        SizedBox(height: w * 0.04),

        _buildLabel(context, 'Tutar (₺)', w),
        SizedBox(height: w * 0.02),
        _buildAmountField(w),
        SizedBox(height: w * 0.04),

        _buildLabel(context, 'Tarih', w),
        SizedBox(height: w * 0.02),
        _buildDateSelector(context, theme, w),
        SizedBox(height: w * 0.04),

        _buildLabel(context, 'Açıklama (Opsiyonel)', w),
        SizedBox(height: w * 0.02),
        _buildDescriptionField(w),
      ],
    );
  }

  Widget _buildLabel(BuildContext context, String text, double w) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: w * 0.035,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildExpenseTypeField(double w) {
    return TextFormField(
      controller: expenseTypeController,
      decoration: InputDecoration(
        hintText: 'Örn: 1 ton demir',
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Masraf türü girin';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown(double w) {
    return DropdownButtonFormField<ExpenseCategory>(
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
        if (value != null) onCategoryChanged(value);
      },
    );
  }

  Widget _buildAmountField(double w) {
    return TextFormField(
      controller: amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        CurrencyInputFormatter(),
      ],
      decoration: InputDecoration(
        hintText: '0',
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Tutar girin';
        }
        final cleanValue = value.replaceAll('.', '');
        final amount = double.tryParse(cleanValue);
        if (amount == null || amount <= 0) {
          return 'Geçerli bir tutar girin';
        }
        return null;
      },
    );
  }

  Widget _buildDateSelector(BuildContext context, ThemeData theme, double w) {
    return InkWell(
      onTap: onDateTap,
      borderRadius: BorderRadius.circular(ExpenseDialogConstants.borderRadius),
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
              DateFormat(
                ExpenseDialogConstants.dateFormat,
                ExpenseDialogConstants.locale,
              ).format(selectedDate),
              style: TextStyle(
                fontSize: w * 0.04,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField(double w) {
    return TextFormField(
      controller: descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Masraf açıklaması...',
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
    );
  }
}
