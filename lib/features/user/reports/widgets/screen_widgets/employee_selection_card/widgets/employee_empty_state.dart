import 'package:flutter/material.dart';

/// Çalışan bulunamadı boş durum widget'ı
class EmployeeEmptyState extends StatelessWidget {
  final bool isDark;

  const EmployeeEmptyState({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search,
              size: 40,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Çalışan bulunamadı',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
