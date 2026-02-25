import 'package:flutter/material.dart';
import '../../../../models/attendance.dart' as attendance;
import '../../../../models/employee.dart';

/// İstatistik ve aksiyon çubuğu widget'ı
class AttendanceStatsBar extends StatelessWidget {
  final List<Employee> filteredEmployees;
  final Map<int, attendance.AttendanceStatus> pendingChanges;
  final Map<int, attendance.Attendance> attendanceMap;
  final bool isToday;
  final VoidCallback onSave;
  final VoidCallback onSendReminders;

  const AttendanceStatsBar({
    super.key,
    required this.filteredEmployees,
    required this.pendingChanges,
    required this.attendanceMap,
    required this.isToday,
    required this.onSave,
    required this.onSendReminders,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // İstatistikleri hesapla
    final present = filteredEmployees.where((e) {
      final status = pendingChanges[e.id] ?? attendanceMap[e.id]?.status;
      return status == attendance.AttendanceStatus.fullDay;
    }).length;

    final absent = filteredEmployees.where((e) {
      final status = pendingChanges[e.id] ?? attendanceMap[e.id]?.status;
      return status == attendance.AttendanceStatus.absent;
    }).length;

    final halfDay = filteredEmployees.where((e) {
      final status = pendingChanges[e.id] ?? attendanceMap[e.id]?.status;
      return status == attendance.AttendanceStatus.halfDay;
    }).length;

    return Container(
      margin: EdgeInsets.all(screenWidth * 0.04),
      padding: EdgeInsets.all(screenWidth * 0.035),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
        boxShadow: theme.brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 30,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: screenWidth * 0.025,
              runSpacing: screenHeight * 0.01,
              children: [
                _buildStatChip(context, '✓', present, const Color(0xFF4F5FBF)),
                _buildStatChip(context, '✗', absent, const Color(0xFFE89595)),
                _buildStatChip(context, '½', halfDay, const Color(0xFF8B9FE8)),
              ],
            ),
          ),
          if (pendingChanges.isNotEmpty) ...[
            SizedBox(width: screenWidth * 0.025),
            FilledButton.icon(
              onPressed: onSave,
              icon: Icon(Icons.save, size: screenWidth * 0.045),
              label: Text(
                'Kaydet',
                style: TextStyle(fontSize: screenWidth * 0.037),
              ),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.012,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
              ),
            ),
          ],
          if (isToday && pendingChanges.isEmpty) ...[
            SizedBox(width: screenWidth * 0.025),
            IconButton(
              onPressed: onSendReminders,
              icon: Icon(Icons.notifications_active, size: screenWidth * 0.05),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                foregroundColor: theme.colorScheme.primary,
                padding: EdgeInsets.all(screenWidth * 0.025),
              ),
              tooltip: 'Hatırlatma Gönder',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    String icon,
    int count,
    Color color,
  ) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.025,
        vertical: screenHeight * 0.008,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(screenWidth * 0.025),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(width: screenWidth * 0.015),
          Text(
            '$count',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: screenWidth * 0.035,
            ),
          ),
        ],
      ),
    );
  }
}
