import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../models/employee_reminder.dart';
import '../../../../../../screens/constants/colors.dart';
import '../../../../employee_reminder_detail/screens/employee_reminder_detail_screen.dart';
import 'reminder_list_delete_dialog.dart';
import 'reminder_list_helpers.dart';

/// Hatırlatıcı kartı widget
class ReminderListItemCard extends StatelessWidget {
  final EmployeeReminder reminder;
  final int reminderIndex;
  final VoidCallback onRefresh;
  final Function(int index, EmployeeReminder reminder) onDelete;

  const ReminderListItemCard({
    required this.reminder,
    required this.reminderIndex,
    required this.onRefresh,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = ReminderListHelpers.calculateStatus(reminder);
    final statusInfo = ReminderListHelpers.getStatusInfo(status, colorScheme);

    return Dismissible(
      key: Key('reminder_${reminder.id}'),
      background: _buildDismissBackground(),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await ReminderListDeleteDialog.show(context);
      },
      onDismissed: (direction) {
        onDelete(reminderIndex, reminder);
      },
      child: _buildCard(context, colorScheme, statusInfo),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete, color: Colors.white, size: 32),
          SizedBox(height: 4),
          Text(
            'Sil',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    ColorScheme colorScheme,
    ReminderStatusInfo statusInfo,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
      child: InkWell(
        onTap: () => _navigateToDetail(context),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 16),
              Expanded(child: _buildContent(colorScheme, statusInfo)),
              const SizedBox(width: 12),
              _buildStatusBadge(statusInfo),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryIndigo, primaryIndigo.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          reminder.workerName[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme, ReminderStatusInfo statusInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reminder.workerName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.access_time, size: 14, color: statusInfo.color),
            const SizedBox(width: 4),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(reminder.reminderDate),
              style: TextStyle(
                fontSize: 13,
                color: statusInfo.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          reminder.message,
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusBadge(ReminderStatusInfo statusInfo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: statusInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: statusInfo.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(statusInfo.icon, color: statusInfo.color, size: 20),
          const SizedBox(height: 4),
          Text(
            statusInfo.text,
            style: TextStyle(
              fontSize: 10,
              color: statusInfo.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToDetail(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            EmployeeReminderDetailScreen(reminderId: reminder.id),
      ),
    );

    if (result == true) {
      onRefresh();
    }
  }
}
