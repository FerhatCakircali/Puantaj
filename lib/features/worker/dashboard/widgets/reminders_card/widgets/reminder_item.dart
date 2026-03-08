import 'package:flutter/material.dart';
import '../helpers/reminder_date_formatter.dart';
import 'reminder_detail_dialog.dart';

/// Hatırlatıcı öğesi widget'ı
///
/// Tek bir hatırlatıcıyı gösterir.
class ReminderItem extends StatelessWidget {
  final Map<String, dynamic> reminder;

  const ReminderItem({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dateUtc = DateTime.parse(reminder['reminder_date']);
    final date = dateUtc.toLocal();
    final message = reminder['message'] as String;
    final managerName = reminder['manager_name'] as String;

    final isToday = ReminderDateFormatter.isToday(date);
    final dateText = ReminderDateFormatter.formatShortDate(date);

    return InkWell(
      onTap: () => ReminderDetailDialog.show(
        context,
        message: message,
        managerName: managerName,
        date: date,
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
            _buildIcon(w, isToday),
            SizedBox(width: w * 0.03),
            Expanded(child: _buildContent(w, h, theme, message, managerName)),
            SizedBox(width: w * 0.02),
            _buildDateBadge(w, h, dateText, isToday),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(double w, bool isToday) {
    return Container(
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
    );
  }

  Widget _buildContent(
    double w,
    double h,
    ThemeData theme,
    String message,
    String managerName,
  ) {
    return Column(
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
    );
  }

  Widget _buildDateBadge(double w, double h, String dateText, bool isToday) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: h * 0.005),
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
    );
  }
}
