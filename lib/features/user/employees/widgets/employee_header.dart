import 'package:flutter/material.dart';

/// Çalışan listesi başlık widget'ı (sayaç ve toplu silme butonu)
class EmployeeHeader extends StatelessWidget {
  final int employeeCount;
  final VoidCallback onDeleteAll;

  const EmployeeHeader({
    super.key,
    required this.employeeCount,
    required this.onDeleteAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$employeeCount Çalışan',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        TextButton.icon(
          onPressed: onDeleteAll,
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Tüm Çalışanları Sil'),
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
        ),
      ],
    );
  }
}
