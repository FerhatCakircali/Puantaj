import 'package:flutter/material.dart';

/// Bildirim bölüm başlığı widget'ı
///
/// Timeline listesinde tarih başlıklarını gösterir.
class NotificationSectionHeader extends StatelessWidget {
  final String title;

  const NotificationSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(top: h * 0.015, bottom: h * 0.01),
      child: Row(
        children: [
          Container(
            width: w * 0.012,
            height: w * 0.012,
            decoration: BoxDecoration(
              color: const Color(0xFF4338CA).withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: w * 0.025),
          Text(
            title,
            style: TextStyle(
              fontSize: w * 0.038,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.shade300,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
