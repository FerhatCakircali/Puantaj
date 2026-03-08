import 'package:flutter/material.dart';
import '../../payment_stat_chip.dart';
import '../../../../../../../screens/constants/colors.dart';

/// Ödeme istatistiklerini gösteren widget (tam/yarım gün)
class PaymentCardStats extends StatelessWidget {
  final int fullDays;
  final int halfDays;

  const PaymentCardStats({
    super.key,
    required this.fullDays,
    required this.halfDays,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Row(
      children: [
        Expanded(
          child: PaymentStatChip(
            label: 'Tam',
            value: fullDays,
            color: fullDayColor,
          ),
        ),
        SizedBox(width: w * 0.02),
        Expanded(
          child: PaymentStatChip(
            label: 'Yarım',
            value: halfDays,
            color: halfDayColor,
          ),
        ),
      ],
    );
  }
}
