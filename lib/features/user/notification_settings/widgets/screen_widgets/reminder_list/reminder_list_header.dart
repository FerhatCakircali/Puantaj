import 'package:flutter/material.dart';

import '../../../../../../screens/constants/colors.dart';

/// Liste başlığı widget
class ReminderListHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  final double padding;

  const ReminderListHeader({
    required this.onRefresh,
    required this.padding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(padding, padding, padding, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryIndigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.list_alt, color: primaryIndigo, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Mevcut Hatırlatıcılar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
            tooltip: 'Yenile',
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
            ),
          ),
        ],
      ),
    );
  }
}
