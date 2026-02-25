import 'package:flutter/material.dart';

/// Ödeme istatistik chip widget'ı
/// Tam/Yarım gün sayılarını gösterir
class PaymentStatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const PaymentStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.02, vertical: h * 0.012),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.2)
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: w * 0.055,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.0,
            ),
          ),
          SizedBox(height: h * 0.004),
          Text(
            label,
            style: TextStyle(
              fontSize: w * 0.03,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
