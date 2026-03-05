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
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final isSmallScreen = w < 360;

    final initial = employee.name.isNotEmpty
        ? employee.name[0].toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(w * 0.06),
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
        padding: EdgeInsets.all(w * 0.04),
        child: Row(
          children: [
            _buildAvatar(initial, w, isSmallScreen),
            SizedBox(width: w * 0.03),
            Expanded(child: _buildEmployeeInfo(theme, w, isSmallScreen)),
            SizedBox(width: w * 0.02),
            _buildQuickActions(theme, w, isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String initial, double w, bool isSmallScreen) {
    final avatarSize = isSmallScreen ? w * 0.14 : w * 0.16;
    final fontSize = isSmallScreen ? w * 0.06 : w * 0.07;

    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryIndigo, primaryIndigo.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(w * 0.05),
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
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeInfo(ThemeData theme, double w, bool isSmallScreen) {
    final titleFontSize = isSmallScreen ? w * 0.04 : w * 0.045;
    final iconSize = isSmallScreen ? w * 0.035 : w * 0.038;
    final bodyFontSize = isSmallScreen ? w * 0.032 : w * 0.035;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          employee.name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            fontSize: titleFontSize,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: w * 0.01),
        if (employee.title.isNotEmpty)
          Row(
            children: [
              Icon(
                Icons.work_outline_rounded,
                size: iconSize,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              SizedBox(width: w * 0.01),
              Flexible(
                child: Text(
                  employee.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                    fontSize: bodyFontSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        if (employee.phone.isNotEmpty) ...[
          SizedBox(height: w * 0.01),
          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                size: iconSize,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              SizedBox(width: w * 0.01),
              Flexible(
                child: Text(
                  employee.phone,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                    fontSize: bodyFontSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme, double w, bool isSmallScreen) {
    final buttonSize = isSmallScreen ? w * 0.09 : w * 0.1;
    final iconSize = isSmallScreen ? w * 0.045 : w * 0.05;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: ValueKey('edit_${employee.id}'),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(w * 0.03),
          ),
          child: IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit_outlined, size: iconSize),
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              padding: EdgeInsets.all(w * 0.025),
              minimumSize: Size(buttonSize, buttonSize),
            ),
            tooltip: 'Düzenle',
          ),
        ),
        SizedBox(height: w * 0.02),
        Container(
          key: ValueKey('delete_${employee.id}'),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(w * 0.03),
          ),
          child: IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, size: iconSize),
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onErrorContainer,
              padding: EdgeInsets.all(w * 0.025),
              minimumSize: Size(buttonSize, buttonSize),
            ),
            tooltip: 'Sil',
          ),
        ),
      ],
    );
  }
}
