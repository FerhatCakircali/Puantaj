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
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final isSmallScreen = w < 360;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            '$employeeCount Çalışan',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? w * 0.04 : w * 0.042,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: TextButton.icon(
            onPressed: onDeleteAll,
            icon: Icon(Icons.delete_outline, size: isSmallScreen ? 16 : 18),
            label: Text(
              isSmallScreen ? 'Tümünü Sil' : 'Tüm Çalışanları Sil',
              overflow: TextOverflow.ellipsis,
            ),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.02,
                vertical: w * 0.01,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
