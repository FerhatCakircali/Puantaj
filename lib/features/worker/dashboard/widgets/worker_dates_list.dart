import 'package:flutter/material.dart';

/// Tarih listesi widget'ı (genişletilebilir içerik)
class WorkerDatesList extends StatelessWidget {
  final List<String> dates;
  final Color color;
  final String label;

  const WorkerDatesList({
    super.key,
    required this.dates,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? color.withValues(alpha: 0.12)
        : color.withValues(alpha: 0.08);
    final borderColor = isDark
        ? color.withValues(alpha: 0.3)
        : color.withValues(alpha: 0.2);
    final textColor = isDark ? color.withValues(alpha: 0.9) : color;

    return Container(
      margin: EdgeInsets.only(top: h * 0.01),
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.015),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.event_note, color: textColor, size: w * 0.04),
              ),
              SizedBox(width: w * 0.02),
              Text(
                'Günlerin Tarihi ($label)',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: w * 0.037,
                ),
              ),
            ],
          ),
          SizedBox(height: h * 0.015),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: h * 0.25),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: w * 0.02,
                runSpacing: h * 0.01,
                children: dates.map((date) {
                  final parsedDate = DateTime.parse(date);
                  final formattedDate =
                      '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.03,
                      vertical: h * 0.008,
                    ),
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: textColor.withValues(alpha: 0.25),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      formattedDate,
                      style: TextStyle(
                        color: textColor,
                        fontSize: w * 0.035,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
