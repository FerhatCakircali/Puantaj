import 'package:flutter/material.dart';
import '../helpers/reminder_date_formatter.dart';

/// Hatırlatıcı detay dialog'u
///
/// Hatırlatıcının tüm detaylarını gösterir.
class ReminderDetailDialog extends StatelessWidget {
  final String message;
  final String managerName;
  final DateTime date;

  const ReminderDetailDialog({
    super.key,
    required this.message,
    required this.managerName,
    required this.date,
  });

  /// Dialog'u gösterir
  static void show(
    BuildContext context, {
    required String message,
    required String managerName,
    required DateTime date,
  }) {
    showDialog(
      context: context,
      builder: (context) => ReminderDetailDialog(
        message: message,
        managerName: managerName,
        date: date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isToday = ReminderDateFormatter.isToday(date);

    return AlertDialog(
      title: _buildTitle(w, isToday),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDateTimeInfo(w, h, date, isToday),
            SizedBox(height: h * 0.02),
            _buildManagerInfo(w, theme, managerName),
            SizedBox(height: h * 0.02),
            _buildMessage(w, theme, isDark, message),
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
    );
  }

  Widget _buildTitle(double w, bool isToday) {
    return Row(
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
            style: TextStyle(fontSize: w * 0.045, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeInfo(double w, double h, DateTime date, bool isToday) {
    return Container(
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
                ReminderDateFormatter.formatLongDate(date),
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
                ReminderDateFormatter.formatTime(date),
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
    );
  }

  Widget _buildManagerInfo(double w, ThemeData theme, String managerName) {
    return Row(
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
    );
  }

  Widget _buildMessage(double w, ThemeData theme, bool isDark, String message) {
    return Container(
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
    );
  }
}
