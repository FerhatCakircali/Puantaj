import 'package:flutter/material.dart';

/// Ödeme gün badge widget'ı
class PaymentDayBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const PaymentDayBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.02, vertical: h * 0.003),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.2)
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: w * 0.028),
          SizedBox(width: w * 0.008),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: w * 0.025,
            ),
          ),
        ],
      ),
    );
  }
}
