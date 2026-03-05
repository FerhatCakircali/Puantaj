import 'package:flutter/material.dart';

/// İstatistik satırı widget'ı (genişletilebilir)
class WorkerStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isExpanded;
  final VoidCallback? onTap;

  const WorkerStatRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isExpanded = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayColor = isDark ? color.withValues(alpha: 0.9) : color;
    final bgColor = isDark
        ? color.withValues(alpha: 0.15)
        : color.withValues(alpha: 0.1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: h * 0.018,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: displayColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.022),
              decoration: BoxDecoration(
                color: displayColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: displayColor, size: w * 0.055),
            ),
            SizedBox(width: w * 0.03),
            Text(
              label,
              style: TextStyle(
                fontSize: w * 0.04,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: w * 0.065,
                fontWeight: FontWeight.w900,
                color: displayColor,
                letterSpacing: -0.5,
              ),
            ),
            if (onTap != null) ...[
              SizedBox(width: w * 0.02),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: w * 0.055,
                color: displayColor.withValues(alpha: 0.6),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
