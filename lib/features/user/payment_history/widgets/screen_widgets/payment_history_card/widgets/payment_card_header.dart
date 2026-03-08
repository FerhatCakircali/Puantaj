import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../../screens/constants/colors.dart';

/// Ödeme kartı başlık widget'ı (avatar, isim, tarih, avans badge)
class PaymentCardHeader extends StatelessWidget {
  final String workerName;
  final DateTime paymentDate;
  final bool isAdvance;

  const PaymentCardHeader({
    super.key,
    required this.workerName,
    required this.paymentDate,
    required this.isAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        _buildAvatar(w, isDark),
        SizedBox(width: w * 0.03),
        Expanded(child: _buildInfo(w, h, theme)),
        Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          size: w * 0.06,
        ),
      ],
    );
  }

  Widget _buildAvatar(double w, bool isDark) {
    return Container(
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
    );
  }

  Widget _buildInfo(double w, double h, ThemeData theme) {
    return Column(
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
    );
  }
}
