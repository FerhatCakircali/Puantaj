import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../models/employee.dart';
import 'date_change_warning.dart';
import 'delete_records_confirmation_dialog.dart';
import 'trusted_status_switch.dart';
import '../controllers/edit_employee_controller.dart';
import 'edit_employee_header.dart';
import 'edit_employee_actions.dart';
import 'edit_employee_text_field.dart';
import 'edit_employee_date_selector.dart';

/// Çalışan düzenleme dialog'u - Modüler tasarım
class EditEmployeeDialog extends StatefulWidget {
  final Employee employee;
  final Future<bool> Function(int employeeId, DateTime date) onCheckRecords;
  final Future<void> Function(int employeeId, DateTime date) onDeleteRecords;
  final Future<void> Function(Employee employee) onUpdate;

  const EditEmployeeDialog({
    super.key,
    required this.employee,
    required this.onCheckRecords,
    required this.onDeleteRecords,
    required this.onUpdate,
  });

  /// Dialog'u göster
  static Future<void> show(
    BuildContext context, {
    required Employee employee,
    required Future<bool> Function(int employeeId, DateTime date)
    onCheckRecords,
    required Future<void> Function(int employeeId, DateTime date)
    onDeleteRecords,
    required Future<void> Function(Employee employee) onUpdate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EditEmployeeDialog(
          employee: employee,
          onCheckRecords: onCheckRecords,
          onDeleteRecords: onDeleteRecords,
          onUpdate: onUpdate,
        ),
      ),
    );
  }

  @override
  State<EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<EditEmployeeDialog> {
  final _controller = EditEmployeeController();
  late TextEditingController nameController;
  late TextEditingController titleController;
  late TextEditingController phoneController;
  late DateTime selectedDate;
  late bool isActive;
  late bool isTrusted;
  bool isStartDateChanged = false;
  bool hasRecordsBeforeNewDate = false;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.employee.name);
    titleController = TextEditingController(text: widget.employee.title);
    phoneController = TextEditingController(text: widget.employee.phone);
    selectedDate = widget.employee.startDate;
    isActive = widget.employee.isActive;
    isTrusted = widget.employee.isTrusted;
  }

  @override
  void dispose() {
    nameController.dispose();
    titleController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleDateSelection() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null || !mounted) return;

    final result = await _controller.handleDateChange(
      newDate: pickedDate,
      originalDate: widget.employee.startDate,
      employeeId: widget.employee.id,
      onCheckRecords: widget.onCheckRecords,
    );

    if (!result.isChanged) return;

    if (!mounted) return;

    setState(() {
      selectedDate = pickedDate;
      isStartDateChanged = result.isChanged;
      hasRecordsBeforeNewDate = result.hasRecordsBeforeNewDate;
    });

    if (result.hasRecordsBeforeNewDate && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'UYARI: Seçilen yeni giriş tarihinden önce bu çalışana ait kayıtlar mevcut. '
            'Değişikliği kaydetmeniz veri tutarsızlığına yol açabilir!',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _handleSave() async {
    if (!_controller.validateForm(
      name: nameController.text,
      title: titleController.text,
      phone: phoneController.text,
    )) {
      return;
    }

    final updatedEmployee = Employee(
      id: widget.employee.id,
      name: nameController.text.trim(),
      title: titleController.text.trim(),
      phone: phoneController.text.trim(),
      startDate: selectedDate,
      userId: widget.employee.userId,
      isActive: isActive,
      isTrusted: isTrusted,
    );

    if (isStartDateChanged && hasRecordsBeforeNewDate) {
      final shouldContinue = await _showDeleteConfirmation();
      if (!shouldContinue || !mounted) return;

      setState(() => isProcessing = true);

      try {
        await _controller.updateWithRecordDeletion(
          employee: updatedEmployee,
          newStartDate: selectedDate,
          onDeleteRecords: widget.onDeleteRecords,
          onUpdate: widget.onUpdate,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Çalışan bilgileri güncellendi. ${DateFormat('dd/MM/yyyy').format(selectedDate)} tarihinden önceki kayıtlar silindi.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem sırasında bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => isProcessing = false);
        }
      }
    } else {
      try {
        await _controller.updateEmployee(
          employee: updatedEmployee,
          onUpdate: widget.onUpdate,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Çalışan bilgileri başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem sırasında bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await DeleteRecordsConfirmationDialog.show(
      context,
      employeeName: widget.employee.name,
      newStartDate: selectedDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          EditEmployeeHeader(
            onClose: () => Navigator.pop(context),
            isProcessing: isProcessing,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EditEmployeeTextField(
                    controller: TextEditingController(
                      text: widget.employee.username ?? 'Kullanıcı adı yok',
                    ),
                    label: 'Kullanıcı Adı',
                    icon: Icons.account_circle,
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  EditEmployeeTextField(
                    controller: nameController,
                    label: 'İsim Soyisim',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  EditEmployeeTextField(
                    controller: titleController,
                    label: 'Unvan',
                    icon: Icons.work_outline,
                  ),
                  const SizedBox(height: 16),
                  EditEmployeeTextField(
                    controller: phoneController,
                    label: 'Telefon',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  EditEmployeeDateSelector(
                    selectedDate: selectedDate,
                    onTap: _handleDateSelection,
                  ),
                  const SizedBox(height: 24),
                  TrustedStatusSwitch(
                    isTrusted: isTrusted,
                    onChanged: (value) {
                      setState(() => isTrusted = value);
                    },
                  ),
                  if (isStartDateChanged && hasRecordsBeforeNewDate)
                    const DateChangeWarning(),
                ],
              ),
            ),
          ),
          EditEmployeeActions(
            onSave: _handleSave,
            onCancel: () => Navigator.pop(context),
            isProcessing: isProcessing,
          ),
        ],
      ),
    );
  }
}
