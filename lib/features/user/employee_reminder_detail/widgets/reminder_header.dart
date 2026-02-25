import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/employee_reminder.dart';

class ReminderHeader extends StatelessWidget {
  final EmployeeReminder reminder;

  const ReminderHeader({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(child: Text(reminder.workerName[0])),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reminder.workerName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hatırlatıcı Tarihi: ${DateFormat('dd/MM/yyyy HH:mm').format(reminder.reminderDate)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
