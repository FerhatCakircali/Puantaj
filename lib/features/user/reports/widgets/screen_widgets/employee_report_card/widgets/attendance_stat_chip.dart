import 'package:flutter/material.dart';

/// Devam istatistik chip widget'ı
class AttendanceStatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool isDark;
  final bool hasDetails;
  final VoidCallback? onTap;

  const AttendanceStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    this.hasDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasDetails ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          boxShadow: hasDetails
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1.0,
                  ),
                ),
                if (hasDetails) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.visibility_outlined,
                    size: 14,
                    color: color.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
