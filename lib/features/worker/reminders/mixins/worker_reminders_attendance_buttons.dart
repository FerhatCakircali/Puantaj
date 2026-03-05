import 'package:flutter/material.dart';

import '../../../../models/attendance.dart';

/// Yevmiye giriş butonları widget
class WorkerRemindersAttendanceButtons extends StatelessWidget {
  final Function(AttendanceStatus) onSubmitAttendance;

  const WorkerRemindersAttendanceButtons({
    required this.onSubmitAttendance,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yevmiye Girişi Yap',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: screenWidth * 0.04,
          ),
        ),
        SizedBox(height: screenWidth * 0.03),
        _buildAttendanceButton(
          context: context,
          label: 'Tam Gün',
          color: const Color(0xFF10B981),
          icon: Icons.check_circle_rounded,
          onPressed: () => onSubmitAttendance(AttendanceStatus.fullDay),
        ),
        SizedBox(height: screenWidth * 0.03),
        _buildAttendanceButton(
          context: context,
          label: 'Yarım Gün',
          color: const Color(0xFFF59E0B),
          icon: Icons.schedule_rounded,
          onPressed: () => onSubmitAttendance(AttendanceStatus.halfDay),
        ),
        SizedBox(height: screenWidth * 0.03),
        _buildAttendanceButton(
          context: context,
          label: 'Gelmedi',
          color: const Color(0xFFEF4444),
          icon: Icons.cancel_rounded,
          onPressed: () => onSubmitAttendance(AttendanceStatus.absent),
        ),
      ],
    );
  }

  Widget _buildAttendanceButton({
    required BuildContext context,
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Center(
      child: SizedBox(
        width: screenWidth * 0.9,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.04),
            ),
            elevation: 2,
            shadowColor: color.withValues(alpha: 0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: screenWidth * 0.06),
              SizedBox(width: screenWidth * 0.03),
              Text(
                label,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
