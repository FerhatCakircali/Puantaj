import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Çalışan giriş tarihi seçici widget'ı
class EmployeeDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const EmployeeDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return InkWell(
      borderRadius: BorderRadius.circular(screenWidth * 0.03),
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          onDateSelected(pickedDate);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: screenWidth * 0.035,
          horizontal: screenWidth * 0.03,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
          ),
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.02),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: colorScheme.primary,
              size: screenWidth * 0.05,
            ),
            SizedBox(width: screenWidth * 0.02),
            Expanded(
              child: Text(
                'Giriş Tarihi: ${dateFmt.format(selectedDate)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Icon(
              Icons.edit_calendar,
              color: Colors.grey,
              size: screenWidth * 0.05,
            ),
          ],
        ),
      ),
    );
  }
}
