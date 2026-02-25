import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Çalışan gün listesi expansion widget'ı
/// Tam gün, yarım gün veya devamsızlık günlerini listeler
class EmployeeDayExpansion extends StatelessWidget {
  final String title;
  final List<DateTime> dates;
  final IconData icon;
  final Color color;

  const EmployeeDayExpansion({
    super.key,
    required this.title,
    required this.dates,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down,
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.grey.shade700,
          ),
          children: dates
              .map(
                (date) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy - EEEE', 'tr_TR').format(date),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
