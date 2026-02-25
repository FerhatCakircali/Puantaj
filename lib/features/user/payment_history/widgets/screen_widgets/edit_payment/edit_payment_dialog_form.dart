import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../../utils/formatters/thousands_separator_formatter.dart';
import '../../../../../../screens/constants/colors.dart';

/// Form alanları widget
class EditPaymentDialogForm extends StatelessWidget {
  final TextEditingController fullDaysController;
  final TextEditingController halfDaysController;
  final TextEditingController amountController;
  final int maxFullDays;
  final int maxHalfDays;
  final DateTime paymentDate;
  final DateTime displayTime;
  final bool isDark;

  const EditPaymentDialogForm({
    required this.fullDaysController,
    required this.halfDaysController,
    required this.amountController,
    required this.maxFullDays,
    required this.maxHalfDays,
    required this.paymentDate,
    required this.displayTime,
    required this.isDark,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFullDaysField(),
        const SizedBox(height: 16),
        _buildHalfDaysField(),
        const SizedBox(height: 16),
        _buildAmountField(),
        const SizedBox(height: 16),
        _buildInfoSection(),
      ],
    );
  }

  Widget _buildFullDaysField() {
    return TextField(
      controller: fullDaysController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Tam Gün Sayısı',
        hintText: 'Maks: $maxFullDays',
        prefixIcon: const Icon(Icons.wb_sunny, color: fullDayColor),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: primaryIndigo, width: 2),
        ),
      ),
      onChanged: (value) {
        final val = int.tryParse(value) ?? 0;
        if (val > maxFullDays) {
          fullDaysController.text = maxFullDays.toString();
          fullDaysController.selection = TextSelection.fromPosition(
            TextPosition(offset: fullDaysController.text.length),
          );
        }
      },
    );
  }

  Widget _buildHalfDaysField() {
    return TextField(
      controller: halfDaysController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Yarım Gün Sayısı',
        hintText: 'Maks: $maxHalfDays',
        prefixIcon: const Icon(Icons.wb_twilight, color: halfDayColor),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: primaryIndigo, width: 2),
        ),
      ),
      onChanged: (value) {
        final val = int.tryParse(value) ?? 0;
        if (val > maxHalfDays) {
          halfDaysController.text = maxHalfDays.toString();
          halfDaysController.selection = TextSelection.fromPosition(
            TextPosition(offset: halfDaysController.text.length),
          );
        }
      },
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        ThousandsSeparatorInputFormatter(),
      ],
      decoration: InputDecoration(
        labelText: 'Ödenecek Miktar',
        prefixText: '₺ ',
        prefixIcon: const Icon(Icons.payments, color: primaryIndigo),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: primaryIndigo, width: 2),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Ödeme Tarihi: ${DateFormat('dd/MM/yyyy').format(paymentDate)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.8)
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Son Güncelleme: ${DateFormat('HH:mm').format(displayTime)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.8)
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
