import 'package:flutter/material.dart';
import '../../../../models/employee.dart';
import '../../../../screens/constants/colors.dart';

/// Çalışan kimlik kartı widget'ı
class EmployeeIdentityCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EmployeeIdentityCard({
    super.key,
    required this.employee,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = employee.name.isNotEmpty
        ? employee.name[0].toUpperCase()
        : '?';

    return Hero(
      tag: 'employee_${employee.id}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: theme.brightness == Brightness.light
                ? [
                    BoxShadow(
                      color: const Color(0x0A000000),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                  ]
                : null,
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildAvatar(initial),
                const SizedBox(width: 16),
                Expanded(child: _buildEmployeeInfo(theme)),
                const SizedBox(width: 12),
                _buildQuickActions(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String initial) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryIndigo, primaryIndigo.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryIndigo.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          employee.name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (employee.title.isNotEmpty)
          Row(
            children: [
              Icon(
                Icons.work_outline_rounded,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  employee.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        if (employee.phone.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Text(
                employee.phone,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              padding: const EdgeInsets.all(10),
            ),
            tooltip: 'Düzenle',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onErrorContainer,
              padding: const EdgeInsets.all(10),
            ),
            tooltip: 'Sil',
          ),
        ),
      ],
    );
  }
}
