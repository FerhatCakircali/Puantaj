import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

/// Toplam kazanç kartı widget'ı
class WorkerTotalCard extends StatelessWidget {
  final double totalPayments;

  const WorkerTotalCard({super.key, required this.totalPayments});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryColor = Color(0xFF4338CA);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.06),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.035),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            primaryColor.withValues(alpha: 0.3),
                            primaryColor.withValues(alpha: 0.2),
                          ]
                        : [
                            primaryColor.withValues(alpha: 0.15),
                            primaryColor.withValues(alpha: 0.1),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: primaryColor,
                  size: w * 0.08,
                ),
              ),
              SizedBox(width: w * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toplam Kazanç',
                      style: TextStyle(
                        fontSize: w * 0.045,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: h * 0.003),
                    Text(
                      'Tüm Zamanlar',
                      style: TextStyle(
                        fontSize: w * 0.035,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: h * 0.025),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: h * 0.02,
              horizontal: w * 0.04,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        primaryColor.withValues(alpha: 0.2),
                        primaryColor.withValues(alpha: 0.1),
                      ]
                    : [
                        primaryColor.withValues(alpha: 0.12),
                        primaryColor.withValues(alpha: 0.06),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Text(
              '₺${CurrencyFormatter.format(totalPayments)}',
              style: TextStyle(
                fontSize: w * 0.10,
                fontWeight: FontWeight.w900,
                color: primaryColor,
                letterSpacing: -2,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: h * 0.015),
          Text(
            'Şimdiye kadar aldığınız toplam ödeme',
            style: TextStyle(
              fontSize: w * 0.035,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
