import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Tarih seçici widget'ı
class EditEmployeeDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;

  const EditEmployeeDateSelector({
    super.key,
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
          ),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.02),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Giriş Tarihi: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.edit_calendar, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
