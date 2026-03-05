import 'package:flutter/material.dart';

/// Çalışan listesi boş olduğunda gösterilen widget
class EmployeeEmptyState extends StatelessWidget {
  const EmployeeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final w = size.width;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: w * 0.3,
              height: w * 0.3,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: w * 0.15,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: w * 0.06),
            Text(
              'Henüz çalışan yok',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                fontSize: w * 0.055,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: w * 0.02),
            Text(
              'Yeni çalışan eklemek için butona tıklayın',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: w * 0.038,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
