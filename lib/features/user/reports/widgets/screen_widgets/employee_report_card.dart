import 'package:flutter/material.dart';
import '../../../../../models/employee.dart';
import 'employee_report_card/widgets/employee_avatar.dart';
import 'employee_report_card/widgets/employee_info.dart';
import 'employee_report_card/widgets/attendance_stat_chip.dart';
import 'employee_report_card/widgets/attendance_dates_dialog.dart';
import 'employee_report_card/constants/attendance_colors.dart';

/// Çalışan rapor kartı - Modern tasarım
class EmployeeReportCard extends StatelessWidget {
  final Employee employee;
  final Map<String, dynamic> stats;
  final VoidCallback onTap;
  final bool isTablet;

  const EmployeeReportCard({
    super.key,
    required this.employee,
    required this.stats,
    required this.onTap,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fontSize = isTablet ? 18.0 : 16.0;

    final fullDays = stats['fullDays'] ?? 0;
    final halfDays = stats['halfDays'] ?? 0;
    final absentDays = stats['absentDays'] ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                EmployeeAvatar(name: employee.name),
                const SizedBox(width: 12),
                Expanded(
                  child: EmployeeInfo(
                    name: employee.name,
                    title: employee.title,
                    fontSize: fontSize,
                    isDark: isDark,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AttendanceStatChip(
                    label: 'Tam',
                    value: fullDays,
                    color: AttendanceColors.fullDay,
                    isDark: isDark,
                    hasDetails: _getDatesForLabel('Tam').isNotEmpty,
                    onTap: () => _showDatesDialog(
                      context,
                      'Tam',
                      _getDatesForLabel('Tam'),
                      AttendanceColors.fullDay,
                      isDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AttendanceStatChip(
                    label: 'Yarım',
                    value: halfDays,
                    color: AttendanceColors.halfDay,
                    isDark: isDark,
                    hasDetails: _getDatesForLabel('Yarım').isNotEmpty,
                    onTap: () => _showDatesDialog(
                      context,
                      'Yarım',
                      _getDatesForLabel('Yarım'),
                      AttendanceColors.halfDay,
                      isDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AttendanceStatChip(
                    label: 'Gelmedi',
                    value: absentDays,
                    color: AttendanceColors.absent,
                    isDark: isDark,
                    hasDetails: _getDatesForLabel('Gelmedi').isNotEmpty,
                    onTap: () => _showDatesDialog(
                      context,
                      'Gelmedi',
                      _getDatesForLabel('Gelmedi'),
                      AttendanceColors.absent,
                      isDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<DateTime> _getDatesForLabel(String label) {
    if (label == 'Tam') {
      return List<DateTime>.from(stats['fullDayDates'] ?? []);
    } else if (label == 'Yarım') {
      return List<DateTime>.from(stats['halfDayDates'] ?? []);
    } else if (label == 'Gelmedi') {
      return List<DateTime>.from(stats['absentDayDates'] ?? []);
    }
    return [];
  }

  void _showDatesDialog(
    BuildContext context,
    String label,
    List<DateTime> dates,
    Color color,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) => AttendanceDatesDialog(
        label: label,
        dates: dates,
        color: color,
        isDark: isDark,
      ),
    );
  }
}
