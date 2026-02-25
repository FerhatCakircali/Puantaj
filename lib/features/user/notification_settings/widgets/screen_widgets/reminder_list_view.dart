import 'package:flutter/material.dart';

import '../../../../../models/employee_reminder.dart';
import 'reminder_list/index.dart';

class ReminderListView extends StatelessWidget {
  final List<EmployeeReminder> reminders;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(int index, EmployeeReminder reminder) onDelete;
  final VoidCallback onAddNew;

  const ReminderListView({
    super.key,
    required this.reminders,
    required this.isLoading,
    required this.onRefresh,
    required this.onDelete,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final padding = isTablet ? 24.0 : 16.0;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reminders.isEmpty) {
      return const ReminderListEmptyView();
    }

    return Column(
      children: [
        ReminderListHeader(onRefresh: onRefresh, padding: padding),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
            itemCount: reminders.length + 1,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return ReminderListAddCard(onAddNew: onAddNew);
              }

              final reminderIndex = index - 1;
              final reminder = reminders[reminderIndex];
              return ReminderListItemCard(
                reminder: reminder,
                reminderIndex: reminderIndex,
                onRefresh: onRefresh,
                onDelete: onDelete,
              );
            },
          ),
        ),
      ],
    );
  }
}
