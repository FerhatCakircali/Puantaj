import 'package:flutter/material.dart';

/// Devam tarihlerini gösteren dialog widget'ı
class AttendanceDatesDialog extends StatelessWidget {
  final String label;
  final List<DateTime> dates;
  final Color color;
  final bool isDark;

  const AttendanceDatesDialog({
    super.key,
    required this.label,
    required this.dates,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, title) = _getIconAndTitle();

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: dates.length,
                itemBuilder: (context, index) {
                  final date = dates[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: color),
                        const SizedBox(width: 12),
                        Text(
                          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, String) _getIconAndTitle() {
    if (label == 'Tam') {
      return (Icons.wb_sunny, 'Tam Gün Çalıştığı Günler');
    } else if (label == 'Yarım') {
      return (Icons.wb_twilight, 'Yarım Gün Çalıştığı Günler');
    } else {
      return (Icons.cancel_outlined, 'Gelmediği Günler');
    }
  }
}
