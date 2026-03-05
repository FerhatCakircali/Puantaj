import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/advance.dart';
import '../../../user/payments/utils/currency_formatter.dart';

/// Avans listesi için kart widget'ı
class AdvanceListTile extends StatelessWidget {
  final Advance advance;
  final String workerName;
  final VoidCallback onTap;
  final Color primaryColor;

  const AdvanceListTile({
    super.key,
    required this.advance,
    required this.workerName,
    required this.onTap,
    this.primaryColor = const Color(0xFF4338CA),
  });

  // Gradient'i cache'le (her build'de yeniden oluşturma)
  LinearGradient _getGradient() {
    return LinearGradient(
      colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // BoxShadow'u cache'le
  List<BoxShadow> _getShadow() {
    return [
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.3),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDeducted = advance.isDeducted;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        return Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Opacity(
                opacity: isDeducted ? 0.6 : 1.0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.04,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: isDeducted
                        ? Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Sol taraf - Baş harf avatar veya check ikonu
                      Container(
                        width: w * 0.11,
                        height: w * 0.11,
                        decoration: BoxDecoration(
                          gradient: isDeducted
                              ? LinearGradient(
                                  colors: [Colors.green, Colors.green.shade700],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : _getGradient(),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _getShadow(),
                        ),
                        child: Center(
                          child: isDeducted
                              ? Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: w * 0.06,
                                )
                              : Text(
                                  workerName.isNotEmpty
                                      ? workerName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: w * 0.05,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: w * 0.03),
                      // Orta - Çalışan ve tarih bilgisi
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workerName,
                              style: TextStyle(
                                fontSize: w * 0.045,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: w * 0.035,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                SizedBox(width: w * 0.01),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                    'tr_TR',
                                  ).format(advance.advanceDate),
                                  style: TextStyle(
                                    fontSize: w * 0.035,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: w * 0.02),
                                // Durum badge
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: w * 0.02,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDeducted
                                        ? Colors.green.withValues(alpha: 0.2)
                                        : Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isDeducted ? 'Düşüldü' : 'Bekliyor',
                                    style: TextStyle(
                                      fontSize: w * 0.028,
                                      color: isDeducted
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Sağ taraf - Tutar
                      Text(
                        '₺${CurrencyFormatter.format(advance.amount)}',
                        style: TextStyle(
                          fontSize: w * 0.05,
                          fontWeight: FontWeight.w900,
                          color: isDeducted ? Colors.green : primaryColor,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
