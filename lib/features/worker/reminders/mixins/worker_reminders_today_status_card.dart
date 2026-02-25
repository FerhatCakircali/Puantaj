import 'package:flutter/material.dart';

import 'worker_reminders_attendance_buttons.dart';
import 'worker_reminders_helpers.dart';

/// Bugünkü durum kartı widget
class WorkerRemindersTodayStatusCard extends StatelessWidget {
  final Map<String, dynamic>? todayStatus;
  final void Function(dynamic) onSubmitAttendance;

  const WorkerRemindersTodayStatusCard({
    required this.todayStatus,
    required this.onSubmitAttendance,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTodayStatusContent(context),
            if (todayStatus?['can_submit'] == true) ...[
              Divider(height: screenWidth * 0.08),
              WorkerRemindersAttendanceButtons(
                onSubmitAttendance: onSubmitAttendance,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatusContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final canSubmit = todayStatus?['can_submit'] == true;
    final statusType = todayStatus?['status_type'] as String?;
    final statusValue = todayStatus?['status_value'] as String?;

    IconData icon;
    Color iconColor;
    Color bgColor;
    String message;

    if (canSubmit) {
      // Durum 1: Yevmiye yapılabilir veya reddedildi
      if (statusType == 'rejected') {
        // Reddedildi - yeniden giriş yapabilir
        icon = Icons.info_outline;
        iconColor = theme.colorScheme.primary;
        bgColor = isDark
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : theme.colorScheme.primary.withValues(alpha: 0.08);
        message = 'Talebiniz reddedildi. Yeniden giriş yapabilirsiniz.';
      } else {
        // Normal durum - ilk kez giriş yapabilir
        icon = Icons.info_outline;
        iconColor = theme.colorScheme.primary;
        bgColor = isDark
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : theme.colorScheme.primary.withValues(alpha: 0.08);
        message = 'Bugün için yevmiye girişi yapabilirsiniz';
      }
    } else if (statusType == 'pending') {
      // Durum 2: Talep onay bekliyor
      icon = Icons.schedule;
      iconColor = Colors.orange;
      bgColor = isDark
          ? Colors.orange.withValues(alpha: 0.15)
          : Colors.orange.withValues(alpha: 0.08);
      final statusText = WorkerRemindersHelpers.getStatusTextFromString(
        statusValue,
      );
      message = 'Talebiniz onay bekliyor: $statusText';
    } else if (statusType == 'manager_entered') {
      // Durum 3: Yönetici girdi
      icon = Icons.cancel;
      iconColor = Colors.red;
      bgColor = isDark
          ? Colors.red.withValues(alpha: 0.15)
          : Colors.red.withValues(alpha: 0.08);
      final statusText = WorkerRemindersHelpers.getStatusTextFromString(
        statusValue,
      );
      message = 'Yöneticiniz bugün için girişinizi yaptı: $statusText';
    } else if (statusType == 'approved') {
      // Onaylandı
      icon = Icons.check_circle;
      iconColor = Colors.green;
      bgColor = isDark
          ? Colors.green.withValues(alpha: 0.15)
          : Colors.green.withValues(alpha: 0.08);
      final statusText = WorkerRemindersHelpers.getStatusTextFromString(
        statusValue,
      );
      message = 'Girişiniz onaylandı: $statusText';
    } else {
      // Diğer durumlar
      icon = Icons.info_outline;
      iconColor = Colors.grey;
      bgColor = isDark
          ? Colors.grey.withValues(alpha: 0.15)
          : Colors.grey.withValues(alpha: 0.08);
      message = todayStatus?['message'] ?? 'Yevmiye girişi yapılamıyor';
    }

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: theme.colorScheme.primary,
                size: screenWidth * 0.05,
              ),
              SizedBox(width: screenWidth * 0.02),
              Text(
                'Bugünkü Durum',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: screenWidth * 0.04,
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.03),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: screenWidth * 0.06),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.w500,
                    fontSize: screenWidth * 0.035,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
