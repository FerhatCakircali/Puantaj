import 'package:flutter/material.dart';

/// Çalışan bilgi widget'ı (isim ve ünvan)
class EmployeeInfo extends StatelessWidget {
  final String name;
  final String title;
  final double fontSize;
  final bool isDark;

  const EmployeeInfo({
    super.key,
    required this.name,
    required this.title,
    required this.fontSize,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (title.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: fontSize * 0.875,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
