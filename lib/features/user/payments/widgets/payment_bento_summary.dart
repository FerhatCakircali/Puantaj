import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

/// Ödeme ekranı özet kartları (Bento Layout)
class PaymentBentoSummary extends StatelessWidget {
  final String currentMonth;
  final double monthlyPaidAmount;
  final int employeeCount;
  final double totalUnpaidDays;

  const PaymentBentoSummary({
    super.key,
    required this.currentMonth,
    required this.monthlyPaidAmount,
    required this.employeeCount,
    required this.totalUnpaidDays,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    return Column(
      children: [
        // Ana Kart - Mevcut Ay Ödenen
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(w * 0.06),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$currentMonth Ayında Ödenen',
                style: TextStyle(
                  fontSize: w * 0.04,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: h * 0.01),
              Text(
                '₺${CurrencyFormatter.format(monthlyPaidAmount)}',
                style: TextStyle(
                  fontSize: w * 0.10,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -2,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: h * 0.015),
        // Küçük Kartlar - Yan yana
        Row(
          children: [
            // Küçük Kart 1 - Çalışan
            Expanded(
              child: _buildSmallCard(
                context,
                title: 'Çalışan',
                value: '$employeeCount',
                w: w,
                h: h,
                theme: theme,
              ),
            ),
            SizedBox(width: w * 0.03),
            // Küçük Kart 2 - Kalan Toplam Gün
            Expanded(
              child: _buildSmallCard(
                context,
                title: 'Kalan Toplam Gün',
                value: '${totalUnpaidDays.toStringAsFixed(1)} Gün',
                w: w,
                h: h,
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallCard(
    BuildContext context, {
    required String title,
    required String value,
    required double w,
    required double h,
    required ThemeData theme,
  }) {
    return Container(
      padding: EdgeInsets.all(w * 0.05),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: w * 0.035,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: h * 0.008),
          Text(
            value,
            style: TextStyle(
              fontSize: title == 'Çalışan' ? w * 0.09 : w * 0.07,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}
