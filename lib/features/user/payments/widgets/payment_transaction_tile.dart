import 'package:flutter/material.dart';
import '../../../../models/employee.dart';

/// Ödeme listesi için çalışan kartı
class PaymentTransactionTile extends StatelessWidget {
  final Employee employee;
  final Map<String, int> unpaidDays;
  final double score;
  final VoidCallback onTap;
  final Color primaryColor;

  const PaymentTransactionTile({
    super.key,
    required this.employee,
    required this.unpaidDays,
    required this.score,
    required this.onTap,
    this.primaryColor = const Color(0xFF4338CA),
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: h * 0.012),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(w * 0.05),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Sol taraf - Baş harf avatar
                Container(
                  width: w * 0.12,
                  height: w * 0.12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      employee.name.isNotEmpty
                          ? employee.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: w * 0.055,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: w * 0.04),
                // Orta - Çalışan bilgisi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: TextStyle(
                          fontSize: w * 0.045,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: h * 0.003),
                      Text(
                        '${unpaidDays['fullDays']} tam • ${unpaidDays['halfDays']} yarım',
                        style: TextStyle(
                          fontSize: w * 0.035,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Sağ taraf - Ödenmemiş Toplam Gün Sayısı
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      score.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: w * 0.055,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'GÜN',
                      style: TextStyle(
                        fontSize: w * 0.028,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
