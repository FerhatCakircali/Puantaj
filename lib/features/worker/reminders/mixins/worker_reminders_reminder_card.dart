import 'package:flutter/material.dart';

import 'worker_reminders_helpers.dart';

/// Hatırlatıcı ayarları kartı widget
class WorkerRemindersReminderCard extends StatelessWidget {
  final bool reminderEnabled;
  final TimeOfDay reminderTime;
  final ValueChanged<bool> onReminderToggle;
  final VoidCallback onSelectTime;

  const WorkerRemindersReminderCard({
    required this.reminderEnabled,
    required this.reminderTime,
    required this.onReminderToggle,
    required this.onSelectTime,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final iconBgColor = isDark
        ? theme.colorScheme.primary.withValues(alpha: 0.15)
        : theme.colorScheme.primary.withValues(alpha: 0.1);
    final iconColor = theme.colorScheme.primary;
    final infoBgColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.grey.shade50;
    final infoIconColor = isDark
        ? theme.colorScheme.onSurfaceVariant
        : Colors.grey.shade600;
    final infoTextColor = isDark
        ? theme.colorScheme.onSurfaceVariant
        : Colors.grey.shade700;
    final timeBgColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.grey.shade100;
    final timeTextColor = theme.colorScheme.onSurface;

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
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: iconColor,
                    size: screenWidth * 0.06,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yevmiye Hatırlatıcısı',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                      Text(
                        reminderEnabled ? 'Aktif' : 'Kapalı',
                        style: TextStyle(
                          color: reminderEnabled ? Colors.green : Colors.grey,
                          fontSize: screenWidth * 0.032,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: reminderEnabled,
                  onChanged: onReminderToggle,
                  activeColor: Colors.white,
                  activeTrackColor: theme.colorScheme.primary,
                  inactiveThumbColor: isDark
                      ? Colors.grey.shade300
                      : Colors.white,
                  inactiveTrackColor: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade400,
                  trackOutlineColor: MaterialStateProperty.resolveWith((
                    states,
                  ) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.transparent;
                    }
                    return isDark ? Colors.grey.shade600 : Colors.grey.shade500;
                  }),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.04),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: infoBgColor,
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: screenWidth * 0.045,
                    color: infoIconColor,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Text(
                      'Her gün belirlediğiniz saatte yevmiye girişi yapmanızı hatırlatan bildirim alın.',
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        color: infoTextColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (reminderEnabled) ...[
              SizedBox(height: screenWidth * 0.04),
              InkWell(
                onTap: onSelectTime,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: timeBgColor,
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: theme.colorScheme.primary,
                        size: screenWidth * 0.06,
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Text(
                        'Hatırlatma Saati',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: screenWidth * 0.038,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenWidth * 0.02,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.02,
                          ),
                        ),
                        child: Text(
                          WorkerRemindersHelpers.formatTimeOfDayForDisplay(
                            reminderTime.hour,
                            reminderTime.minute,
                          ),
                          style: TextStyle(
                            color: timeTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
