import 'package:flutter/material.dart';

/// Bekleyen talepler kartı
class PendingRequestsCard extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onTap;

  const PendingRequestsCard({
    super.key,
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const accentColor = Colors.orange;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(w * 0.05),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(w * 0.05),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(w * 0.05),
          border: pendingCount > 0
              ? Border.all(
                  color: accentColor.withValues(alpha: 0.3),
                  width: w * 0.004,
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.03),
              decoration: BoxDecoration(
                color: isDark
                    ? accentColor.withValues(alpha: 0.2)
                    : accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(w * 0.03),
              ),
              child: Icon(
                Icons.pending_actions,
                color: accentColor,
                size: w * 0.06,
              ),
            ),
            SizedBox(width: w * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bekleyen Talepler',
                    style: TextStyle(
                      fontSize: w * 0.04,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: h * 0.003),
                  Text(
                    pendingCount > 0
                        ? '$pendingCount adet talebiniz onay bekliyor'
                        : 'Bekleyen talep yok',
                    style: TextStyle(
                      fontSize: w * 0.033,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (pendingCount > 0)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.03,
                  vertical: h * 0.008,
                ),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(w * 0.05),
                ),
                child: Text(
                  pendingCount.toString(),
                  style: TextStyle(
                    fontSize: w * 0.035,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            SizedBox(width: w * 0.02),
            Icon(
              Icons.arrow_forward_ios,
              size: w * 0.04,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
