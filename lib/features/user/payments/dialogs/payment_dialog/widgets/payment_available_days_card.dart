import 'package:flutter/material.dart';
import '../../../../../../screens/constants/colors.dart';
import 'payment_day_info.dart';

/// Ödeme dialog'unda mevcut gün sayılarını gösteren kart
/// Tam ve yarım gün sayılarını yan yana gösterir
class PaymentAvailableDaysCard extends StatelessWidget {
  final int fullDays;
  final int halfDays;

  const PaymentAvailableDaysCard({
    super.key,
    required this.fullDays,
    required this.halfDays,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryIndigo.withValues(alpha: 0.15),
            primaryIndigo.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryIndigo.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: PaymentDayInfo(
              icon: Icons.wb_sunny,
              label: 'Tam Gün',
              value: fullDays,
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
          Expanded(
            child: PaymentDayInfo(
              icon: Icons.wb_twilight,
              label: 'Yarım Gün',
              value: halfDays,
            ),
          ),
        ],
      ),
    );
  }
}
