import 'package:flutter/material.dart';
import '../../../../../../../screens/constants/colors.dart';

/// Ödeme dialog'unda gün bilgisi gösterimi
/// Tam/Yarım gün sayılarını icon ile birlikte gösterir
class PaymentDayInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const PaymentDayInfo({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Icon(icon, size: 16, color: primaryIndigo),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
