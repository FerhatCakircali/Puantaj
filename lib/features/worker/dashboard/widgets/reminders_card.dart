import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Yaklaşan hatırlatıcılar kartı
class RemindersCard extends StatelessWidget {
  final List<Map<String, dynamic>> reminders;

  const RemindersCard({super.key, required this.reminders});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryColor = Color(0xFF4338CA);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.05),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(w * 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.025),
                decoration: BoxDecoration(
                  color: isDark
                      ? primaryColor.withValues(alpha: 0.2)
                      : primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
                child: Icon(
                  Icons.event_note,
                  color: primaryColor,
                  size: w * 0.06,
                ),
              ),
              SizedBox(width: w * 0.03),
              Text(
                'Yaklaşan Hatırlatıcılar',
                style: TextStyle(
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: h * 0.02),
          if (reminders.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: h * 0.02),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: w * 0.12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    SizedBox(height: h * 0.01),
                    Text(
                      'Hatırlatıcı yok',
                      style: TextStyle(
                        fontSize: w * 0.035,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...reminders.map(
              (reminder) => _buildReminderItem(
                context,
                reminder: reminder,
                isDark: isDark,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(
    BuildContext context, {
    required Map<String, dynamic> reminder,
    required bool isDark,
  }) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    final dateUtc = DateTime.parse(reminder['reminder_date']);
    // Türkiye saatine çevir (UTC+3)
    final date = dateUtc.toLocal();
    final message = reminder['message'] as String;
    final managerName = reminder['manager_name'] as String;

    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isTomorrow =
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day + 1;

    String dateText;
    final timeText = DateFormat('HH:mm', 'tr_TR').format(date);
    if (isToday) {
      dateText = 'Bugün $timeText';
    } else if (isTomorrow) {
      dateText = 'Yarın $timeText';
    } else {
      dateText = '${DateFormat('dd MMM', 'tr_TR').format(date)} $timeText';
    }

    return InkWell(
      onTap: () => _showReminderDetailDialog(
        context,
        message: message,
        managerName: managerName,
        date: date,
        isToday: isToday,
      ),
      borderRadius: BorderRadius.circular(w * 0.03),
      child: Container(
        margin: EdgeInsets.only(bottom: h * 0.012),
        padding: EdgeInsets.all(w * 0.04),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(w * 0.03),
          border: Border.all(
            color: isToday
                ? Colors.orange.withValues(alpha: 0.5)
                : isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
            width: isToday ? w * 0.004 : w * 0.0025,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.02),
              decoration: BoxDecoration(
                color: isToday
                    ? Colors.orange.withValues(alpha: 0.2)
                    : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(w * 0.02),
              ),
              child: Icon(
                isToday ? Icons.alarm : Icons.event,
                color: isToday ? Colors.orange : Colors.blue,
                size: w * 0.05,
              ),
            ),
            SizedBox(width: w * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: w * 0.037,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: h * 0.005),
                  Text(
                    'Yönetici: $managerName',
                    style: TextStyle(
                      fontSize: w * 0.032,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: w * 0.02),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.025,
                vertical: h * 0.005,
              ),
              decoration: BoxDecoration(
                color: isToday
                    ? Colors.orange.withValues(alpha: 0.2)
                    : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(w * 0.02),
              ),
              child: Text(
                dateText,
                style: TextStyle(
                  fontSize: w * 0.03,
                  fontWeight: FontWeight.w600,
                  color: isToday ? Colors.orange : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReminderDetailDialog(
    BuildContext context, {
    required String message,
    required String managerName,
    required DateTime date,
    required bool isToday,
  }) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isToday ? Icons.alarm : Icons.event_note,
              color: isToday ? Colors.orange : Colors.blue,
              size: w * 0.06,
            ),
            SizedBox(width: w * 0.03),
            Expanded(
              child: Text(
                'Hatırlatıcı Detayı',
                style: TextStyle(
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tarih ve saat bilgisi
              Container(
                padding: EdgeInsets.all(w * 0.03),
                decoration: BoxDecoration(
                  color: isToday
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(w * 0.02),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: w * 0.04,
                          color: isToday ? Colors.orange : Colors.blue,
                        ),
                        SizedBox(width: w * 0.02),
                        Text(
                          DateFormat(
                            'dd MMMM yyyy, EEEE',
                            'tr_TR',
                          ).format(date),
                          style: TextStyle(
                            fontSize: w * 0.035,
                            fontWeight: FontWeight.w600,
                            color: isToday ? Colors.orange : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: h * 0.008),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: w * 0.04,
                          color: isToday ? Colors.orange : Colors.blue,
                        ),
                        SizedBox(width: w * 0.02),
                        Text(
                          DateFormat('HH:mm', 'tr_TR').format(date),
                          style: TextStyle(
                            fontSize: w * 0.035,
                            fontWeight: FontWeight.w600,
                            color: isToday ? Colors.orange : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: h * 0.02),
              // Yönetici bilgisi
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: w * 0.04,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  SizedBox(width: w * 0.02),
                  Text(
                    'Yönetici: ',
                    style: TextStyle(
                      fontSize: w * 0.035,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      managerName,
                      style: TextStyle(
                        fontSize: w * 0.035,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: h * 0.02),
              // Mesaj
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(w * 0.04),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(w * 0.02),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Kapat',
              style: TextStyle(fontSize: w * 0.04, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
