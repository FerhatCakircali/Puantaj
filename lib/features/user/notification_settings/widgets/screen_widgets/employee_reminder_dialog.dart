import 'package:flutter/material.dart';
import '../../../../../models/worker.dart';
import 'employee_reminder_dialog/widgets/reminder_dialog_header.dart';
import 'employee_reminder_dialog/widgets/reminder_date_picker.dart';
import 'employee_reminder_dialog/widgets/reminder_time_picker.dart';
import 'employee_reminder_dialog/widgets/reminder_message_field.dart';
import 'employee_reminder_dialog/widgets/reminder_dialog_actions.dart';
import 'employee_reminder_dialog/handlers/reminder_submission_handler.dart';

/// Çalışan hatırlatıcı ekleme dialog'u
class EmployeeReminderDialog extends StatefulWidget {
  final Worker worker;
  final VoidCallback onReminderAdded;

  const EmployeeReminderDialog({
    super.key,
    required this.worker,
    required this.onReminderAdded,
  });

  @override
  State<EmployeeReminderDialog> createState() => _EmployeeReminderDialogState();
}

class _EmployeeReminderDialogState extends State<EmployeeReminderDialog> {
  final ReminderSubmissionHandler _submissionHandler =
      ReminderSubmissionHandler();
  final TextEditingController _messageController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _saveReminder() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await _submissionHandler.saveReminder(
        context: context,
        worker: widget.worker,
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        message: _messageController.text,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        widget.onReminderAdded();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: ReminderDialogHeader(workerName: widget.worker.fullName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReminderDatePicker(
                selectedDate: _selectedDate,
                onDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
              const SizedBox(height: 16),
              ReminderTimePicker(
                selectedTime: _selectedTime,
                onTimeChanged: (time) {
                  setState(() {
                    _selectedTime = time;
                  });
                },
              ),
              const SizedBox(height: 16),
              ReminderMessageField(controller: _messageController),
            ],
          ),
        ),
        actions: [
          ReminderDialogActions(
            isSubmitting: _isSubmitting,
            onCancel: () => Navigator.pop(context),
            onSave: _saveReminder,
          ),
        ],
      ),
    );
  }
}
