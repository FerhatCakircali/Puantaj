import 'package:flutter/material.dart';
import '../../../../models/attendance.dart' as attendance;
import '../../../../models/employee.dart';
import '../../../../screens/constants/colors.dart';

/// Çalışan kartı widget'ı
class AttendanceEmployeeCard extends StatelessWidget {
  final Employee employee;
  final attendance.AttendanceStatus? status;
  final Function(attendance.AttendanceStatus) onStatusChange;

  const AttendanceEmployeeCard({
    super.key,
    required this.employee,
    required this.status,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    final initial = employee.name.isNotEmpty
        ? employee.name[0].toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        boxShadow: theme.brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 20,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: isSmallScreen ? 40 : 44,
              height: isSmallScreen ? 40 : 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryIndigo, primaryIndigo.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: isSmallScreen ? 10 : 12),
            // Çalışan Bilgisi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      fontSize: isSmallScreen ? 13 : 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (employee.title.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      employee.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: isSmallScreen ? 11 : 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Durum Butonları
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusButton(
                  context,
                  Icons.check_circle,
                  const Color(0xFF4F5FBF),
                  status == attendance.AttendanceStatus.fullDay,
                  () => onStatusChange(attendance.AttendanceStatus.fullDay),
                  isSmallScreen,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                _buildStatusButton(
                  context,
                  Icons.schedule,
                  const Color(0xFF8B9FE8),
                  status == attendance.AttendanceStatus.halfDay,
                  () => onStatusChange(attendance.AttendanceStatus.halfDay),
                  isSmallScreen,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                _buildStatusButton(
                  context,
                  Icons.cancel,
                  const Color(0xFFE89595),
                  status == attendance.AttendanceStatus.absent,
                  () => onStatusChange(attendance.AttendanceStatus.absent),
                  isSmallScreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    BuildContext context,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap,
    bool isSmallScreen,
  ) {
    final buttonSize = isSmallScreen ? 32.0 : 36.0;
    final iconSize = isSmallScreen ? 16.0 : 18.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
          border: isSelected ? Border.all(color: color, width: 2) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: isSelected ? Colors.white : color,
        ),
      ),
    );
  }
}
