import 'package:flutter/material.dart';
import 'reminders_card/widgets/reminder_empty_state.dart';
import 'reminders_card/widgets/reminder_item.dart';

/// Yaklaşan hatırlatıcılar kartı
///
/// Çalışanın yaklaşan hatırlatıcılarını listeler.
class RemindersCard extends StatelessWidget {
  final List<Map<String, dynamic>> reminders;

  const RemindersCard({super.key, required this.reminders});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
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
          _buildHeader(w, isDark, theme, primaryColor),
          SizedBox(height: h * 0.02),
          if (reminders.isEmpty)
            const ReminderEmptyState()
          else
            ...reminders.map((reminder) => ReminderItem(reminder: reminder)),
        ],
      ),
    );
  }

  Widget _buildHeader(
    double w,
    bool isDark,
    ThemeData theme,
    Color primaryColor,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(w * 0.025),
          decoration: BoxDecoration(
            color: isDark
                ? primaryColor.withValues(alpha: 0.2)
                : primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(w * 0.03),
          ),
          child: Icon(Icons.event_note, color: primaryColor, size: w * 0.06),
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
    );
  }
}
