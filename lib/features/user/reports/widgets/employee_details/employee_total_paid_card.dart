import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../../screens/constants/colors.dart';

/// Toplam ödenen miktar kartı
/// Çalışana yapılan toplam ödemeyi ve gün sayılarını gösterir
class EmployeeTotalPaidCard extends StatelessWidget {
  final double totalPaid;
  final int paidFullDays;
  final int paidHalfDays;

  const EmployeeTotalPaidCard({
    super.key,
    required this.totalPaid,
    required this.paidFullDays,
    required this.paidHalfDays,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formattedAmount = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    ).format(totalPaid);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? primaryIndigo.withValues(alpha: 0.2)
            : primaryIndigo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primaryIndigo.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildAmountSection(formattedAmount, isDark),
          const SizedBox(height: 12),
          _buildDaysSection(isDark),
        ],
      ),
    );
  }

  Widget _buildAmountSection(String formattedAmount, bool isDark) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: primaryIndigo.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.payments_outlined,
            color: primaryIndigo,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Toplam Ödenen',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formattedAmount,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : primaryIndigo,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: primaryIndigo,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text(
                'Ödendi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDaysSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wb_sunny, color: primaryIndigo, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$paidFullDays Tam',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.grey.shade300,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wb_twilight, color: primaryIndigo, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$paidHalfDays Yarım',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
