import 'package:flutter/material.dart';

/// Hatırlatıcı boş durum widget'ı
///
/// Hatırlatıcı olmadığında gösterilir.
class ReminderEmptyState extends StatelessWidget {
  const ReminderEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: h * 0.02),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: w * 0.12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: h * 0.01),
            Text(
              'Hatırlatıcı yok',
              style: TextStyle(
                fontSize: w * 0.035,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
