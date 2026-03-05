import 'package:flutter/material.dart';
import '../../../user/payments/utils/currency_formatter.dart';

/// Masraf ekranı özet kartları (Bento Layout)
class ExpenseSummaryCards extends StatelessWidget {
  final double monthlyTotal;
  final double overallTotal;
  final int expenseCount;

  const ExpenseSummaryCards({
    super.key,
    required this.monthlyTotal,
    required this.overallTotal,
    required this.expenseCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final horizontalPadding = w * 0.05;
          final cardSpacing = 10.0;

          return Column(
            children: [
              // Ana Kart - Bu Ay Masraf
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(horizontalPadding),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bu Ay Masraf',
                      style: TextStyle(
                        fontSize: w * 0.035,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '₺${CurrencyFormatter.format(monthlyTotal)}',
                        style: TextStyle(
                          fontSize: w * 0.09,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -1.5,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: cardSpacing),
              // Küçük Kartlar - Yan yana
              Row(
                children: [
                  Expanded(
                    child: _buildSmallCard(
                      context,
                      title: 'Toplam Masraf',
                      value: '₺${CurrencyFormatter.format(overallTotal)}',
                      w: w,
                      theme: theme,
                    ),
                  ),
                  SizedBox(width: w * 0.025),
                  Expanded(
                    child: _buildSmallCard(
                      context,
                      title: 'Masraf Sayısı',
                      value: '$expenseCount Adet',
                      w: w,
                      theme: theme,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSmallCard(
    BuildContext context, {
    required String title,
    required String value,
    required double w,
    required ThemeData theme,
  }) {
    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: w * 0.03,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: w * 0.055,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
