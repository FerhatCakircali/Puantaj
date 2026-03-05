import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/currency_formatter.dart';

/// Ödeme geçmişi kartı
class PaymentHistoryCard extends StatelessWidget {
  final List<Map<String, dynamic>> recentPayments;
  final double monthlyAverage;

  const PaymentHistoryCard({
    super.key,
    required this.recentPayments,
    required this.monthlyAverage,
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
      padding: EdgeInsets.all(w * 0.05),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(w * 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.025),
                decoration: BoxDecoration(
                  color: isDark
                      ? primaryColor.withValues(alpha: 0.2)
                      : primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
                child: Icon(Icons.payment, color: primaryColor, size: w * 0.06),
              ),
              SizedBox(width: w * 0.03),
              Text(
                'Ödeme Geçmişi',
                style: TextStyle(
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: h * 0.02),
          // Aylık ortalama
          Container(
            padding: EdgeInsets.all(w * 0.04),
            decoration: BoxDecoration(
              color: isDark
                  ? primaryColor.withValues(alpha: 0.15)
                  : primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(w * 0.03),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Aylık Ortalama',
                  style: TextStyle(
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  '₺${CurrencyFormatter.format(monthlyAverage)}',
                  style: TextStyle(
                    fontSize: w * 0.045,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: h * 0.02),
          // Son 3 ödeme
          if (recentPayments.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: h * 0.02),
                child: Text(
                  'Henüz ödeme kaydı yok',
                  style: TextStyle(
                    fontSize: w * 0.035,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else
            ...recentPayments.map(
              (payment) =>
                  _buildPaymentItem(context, payment: payment, isDark: isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(
    BuildContext context, {
    required Map<String, dynamic> payment,
    required bool isDark,
  }) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final theme = Theme.of(context);

    final date = DateTime.parse(payment['payment_date']);
    final amount = payment['amount'] as num;
    final fullDays = payment['full_days'] as int;
    final halfDays = payment['half_days'] as int;

    return Container(
      margin: EdgeInsets.only(bottom: h * 0.012),
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.02),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(w * 0.02),
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.green,
              size: w * 0.05,
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(date),
                  style: TextStyle(
                    fontSize: w * 0.037,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: h * 0.003),
                Text(
                  '$fullDays tam, $halfDays yarım gün',
                  style: TextStyle(
                    fontSize: w * 0.032,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₺${CurrencyFormatter.format(amount.toDouble())}',
            style: TextStyle(
              fontSize: w * 0.042,
              fontWeight: FontWeight.w700,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
