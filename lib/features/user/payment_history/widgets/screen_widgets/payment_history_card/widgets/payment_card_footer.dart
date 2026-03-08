import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../../utils/number_formatter.dart';
import '../../../../../../../screens/constants/colors.dart';

/// Ödeme kartı alt bilgi widget'ı (tutar ve saat)
class PaymentCardFooter extends StatelessWidget {
  final double amount;
  final DateTime displayTime;
  final bool isAdvance;

  const PaymentCardFooter({
    super.key,
    required this.amount,
    required this.displayTime,
    required this.isAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '₺${amount.toFormattedString()}',
          style: TextStyle(
            fontSize: w * 0.055,
            fontWeight: FontWeight.w900,
            color: isAdvance ? Colors.orange : primaryIndigo,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        Text(
          DateFormat('HH:mm').format(displayTime),
          style: TextStyle(
            fontSize: w * 0.032,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
