import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../screens/constants/colors.dart';

/// Tarih aralığı seçici widget'ı
class DateRangeSelector extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onTap;

  const DateRangeSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.06, h * 0.02, w * 0.06, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.04,
            vertical: h * 0.016,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? theme.colorScheme.outline.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.02),
                decoration: BoxDecoration(
                  color: primaryIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_today,
                  size: w * 0.045,
                  color: primaryIndigo,
                ),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tarih Aralığı',
                      style: TextStyle(
                        fontSize: w * 0.032,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: h * 0.004),
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                      style: TextStyle(
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.calendar_month, color: primaryIndigo, size: w * 0.055),
            ],
          ),
        ),
      ),
    );
  }
}
