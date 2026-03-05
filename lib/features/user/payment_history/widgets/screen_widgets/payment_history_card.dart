import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../utils/number_formatter.dart';
import '../../../../../screens/constants/colors.dart';
import 'payment_stat_chip.dart';

/// Ödeme geçmişi kartı widget'ı
/// Tek bir ödeme kaydını gösterir
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
    final isDark = theme.brightness == Brightness.dark;

    final isAdvance = payment['is_advance'] as bool? ?? false;
    final workerName = payment['workers']['full_name'] as String;
    final fullDays = payment['full_days'] as int;
    final halfDays = payment['half_days'] as int;
    final amount = (payment['amount'] as num).toDouble();
    final paymentDate = DateTime.parse(payment['payment_date'] as String);
    final description = payment['description'] as String?;

    final displayTime = _getDisplayTime();

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
            _buildHeader(
              w,
              h,
              workerName,
              paymentDate,
              isDark,
              theme,
              isAdvance,
            ),
            SizedBox(height: h * 0.015),
            if (isAdvance)
              _buildAdvanceInfo(w, h, description, isDark, theme)
            else
              _buildStats(w, h, fullDays, halfDays, isDark),
            SizedBox(height: h * 0.015),
            _buildFooter(w, h, amount, displayTime, isDark, theme, isAdvance),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    double w,
    double h,
    String workerName,
    DateTime paymentDate,
    bool isDark,
    ThemeData theme,
    bool isAdvance,
  ) {
    return Row(
      children: [
        Container(
          width: w * 0.12,
          height: w * 0.12,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isAdvance
                  ? isDark
                        ? [
                            Colors.orange.withValues(alpha: 0.3),
                            Colors.orange.withValues(alpha: 0.2),
                          ]
                        : [
                            Colors.orange.withValues(alpha: 0.15),
                            Colors.orange.withValues(alpha: 0.1),
                          ]
                  : isDark
                  ? [
                      primaryIndigo.withValues(alpha: 0.3),
                      primaryIndigo.withValues(alpha: 0.2),
                    ]
                  : [
                      primaryIndigo.withValues(alpha: 0.15),
                      primaryIndigo.withValues(alpha: 0.1),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: isAdvance
                ? Icon(
                    Icons.account_balance_wallet,
                    color: Colors.orange,
                    size: w * 0.06,
                  )
                : Text(
                    workerName.isNotEmpty ? workerName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: w * 0.055,
                      fontWeight: FontWeight.w700,
                      color: primaryIndigo,
                    ),
                  ),
          ),
        ),
        SizedBox(width: w * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isAdvance) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.02,
                        vertical: h * 0.003,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'AVANS',
                        style: TextStyle(
                          fontSize: w * 0.028,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.02),
                  ],
                  Expanded(
                    child: Text(
                      workerName,
                      style: TextStyle(
                        fontSize: w * 0.04,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: h * 0.004),
              Text(
                DateFormat('dd/MM/yyyy').format(paymentDate),
                style: TextStyle(
                  fontSize: w * 0.035,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          size: w * 0.06,
        ),
      ],
    );
  }

  Widget _buildStats(
    double w,
    double h,
    int fullDays,
    int halfDays,
    bool isDark,
  ) {
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

  Widget _buildAdvanceInfo(
    double w,
    double h,
    String? description,
    bool isDark,
    ThemeData theme,
  ) {
    if (description == null || description.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: h * 0.01),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: w * 0.04,
              color: Colors.orange.withValues(alpha: 0.7),
            ),
            SizedBox(width: w * 0.02),
            Text(
              'Açıklama eklenmemiş',
              style: TextStyle(
                fontSize: w * 0.035,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: h * 0.01),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description_outlined,
            size: w * 0.04,
            color: Colors.orange,
          ),
          SizedBox(width: w * 0.02),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: w * 0.035,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    double w,
    double h,
    double amount,
    DateTime displayTime,
    bool isDark,
    ThemeData theme,
    bool isAdvance,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '₺${amount.toFormattedString()}',
          style: TextStyle(
            fontSize: w * 0.055,
            fontWeight: FontWeight.w900,
            color: isAdvance ? Colors.orange : primaryIndigo,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        Text(
          DateFormat('HH:mm').format(displayTime),
          style: TextStyle(
            fontSize: w * 0.032,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  DateTime _getDisplayTime() {
    if (payment['updated_at'] != null) {
      return DateTime.parse(payment['updated_at'] as String).toLocal();
    } else if (payment['created_at'] != null) {
      return DateTime.parse(payment['created_at'] as String).toLocal();
    } else {
      return DateTime.parse(payment['payment_date'] as String);
    }
  }
}
