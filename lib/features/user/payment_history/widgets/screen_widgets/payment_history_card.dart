import 'package:flutter/material.dart';
import 'payment_history_card/widgets/payment_card_header.dart';
import 'payment_history_card/widgets/payment_card_stats.dart';
import 'payment_history_card/widgets/payment_advance_info.dart';
import 'payment_history_card/widgets/payment_card_footer.dart';
import 'payment_history_card/helpers/payment_time_helper.dart';

/// Ödeme geçmişi kartı widget'ı
///
/// Tek bir ödeme kaydını gösterir (normal ödeme veya avans)
class PaymentHistoryCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final VoidCallback onTap;

  const PaymentHistoryCard({
    super.key,
    required this.payment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    final isAdvance = payment['is_advance'] as bool? ?? false;
    final workerName = payment['workers']['full_name'] as String;
    final fullDays = payment['full_days'] as int;
    final halfDays = payment['half_days'] as int;
    final amount = (payment['amount'] as num).toDouble();
    final paymentDate = DateTime.parse(payment['payment_date'] as String);
    final description = payment['description'] as String?;
    final displayTime = PaymentTimeHelper.getDisplayTime(payment);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(w * 0.045),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: isAdvance
              ? Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PaymentCardHeader(
              workerName: workerName,
              paymentDate: paymentDate,
              isAdvance: isAdvance,
            ),
            SizedBox(height: h * 0.015),
            if (isAdvance)
              PaymentAdvanceInfo(description: description)
            else
              PaymentCardStats(fullDays: fullDays, halfDays: halfDays),
            SizedBox(height: h * 0.015),
            PaymentCardFooter(
              amount: amount,
              displayTime: displayTime,
              isAdvance: isAdvance,
            ),
          ],
        ),
      ),
    );
  }
}
