import 'package:flutter/material.dart';

/// Masraf bilgi satırı widget'ı
class ExpenseInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double width;
  final Color? valueColor;
  final bool valueBold;
  final bool multiline;

  const ExpenseInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.width,
    this.valueColor,
    this.valueBold = false,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: multiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: width * 0.05,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: width * 0.032,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: width * 0.04,
                  color: valueColor ?? theme.colorScheme.onSurface,
                  fontWeight: valueBold ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
