import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../helpers/advance_validator.dart';
import '../../../../../utils/currency_input_formatter.dart';

final _validator = AdvanceFormValidator();

/// Avans form alanları widget'ı
///
/// Tutar, tarih ve açıklama alanlarını içerir.
class AdvanceFormFields extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController descriptionController;
  final DateTime selectedDate;
  final VoidCallback onDateTap;

  const AdvanceFormFields({
    super.key,
    required this.amountController,
    required this.descriptionController,
    required this.selectedDate,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = MediaQuery.sizeOf(context).width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAmountField(theme, w),
        SizedBox(height: w * 0.04),
        _buildDateField(theme, w),
        SizedBox(height: w * 0.04),
        _buildDescriptionField(theme, w),
      ],
    );
  }

  Widget _buildAmountField(ThemeData theme, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tutar (₺)',
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
            hintText: '0',
            prefixText: '₺ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
          'Tarih',
          style: TextStyle(
            fontSize: w * 0.035,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: w * 0.02),
        InkWell(
          onTap: onDateTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.04,
              vertical: w * 0.035,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
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
          'Açıklama (Opsiyonel)',
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
            hintText: 'Avans açıklaması...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
