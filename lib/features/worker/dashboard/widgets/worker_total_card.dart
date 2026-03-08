import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

/// Toplam kazanç kartı widget'ı
class WorkerTotalCard extends StatelessWidget {
  final double totalPayments;
  final double? totalAdvances;
  final double? pendingAdvances;

  const WorkerTotalCard({
    super.key,
    required this.totalPayments,
    this.totalAdvances,
    this.pendingAdvances,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
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
          // Avans bilgisi
          if (totalAdvances != null && totalAdvances! > 0) ...[
            SizedBox(height: h * 0.02),
            Container(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
            SizedBox(height: h * 0.015),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.orange,
                      size: w * 0.045,
                    ),
                    SizedBox(width: w * 0.02),
                    Text(
                      'Toplam Avans',
                      style: TextStyle(
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '₺${CurrencyFormatter.format(totalAdvances!)}',
                  style: TextStyle(
                    fontSize: w * 0.042,
                    fontWeight: FontWeight.w800,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            if (pendingAdvances != null && pendingAdvances! > 0) ...[
              SizedBox(height: h * 0.01),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.red, size: w * 0.045),
                      SizedBox(width: w * 0.02),
                      Text(
                        'Bekleyen Avans',
                        style: TextStyle(
                          fontSize: w * 0.038,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₺${CurrencyFormatter.format(pendingAdvances!)}',
                    style: TextStyle(
                      fontSize: w * 0.042,
                      fontWeight: FontWeight.w800,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
