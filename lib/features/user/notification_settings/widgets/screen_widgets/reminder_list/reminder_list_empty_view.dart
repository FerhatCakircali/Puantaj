import 'package:flutter/material.dart';

import '../../../../../../screens/constants/colors.dart';

/// Boş liste görünümü widget
class ReminderListEmptyView extends StatelessWidget {
  const ReminderListEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryIndigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 40,
                color: primaryIndigo,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz hatırlatıcı eklenmemiş',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Çalışanlarınız için hatırlatıcı eklemek için "Çalışanlar" sekmesine geçin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
