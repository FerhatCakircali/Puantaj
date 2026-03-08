import 'package:flutter/material.dart';
import '../../../../models/employee.dart';
import '../../../../models/advance.dart';
import '../controllers/advance_controller.dart';
import 'base_advance_dialog.dart';
import 'helpers/advance_snackbar_helper.dart';
import 'helpers/advance_validator.dart';

final _validator = AdvanceFormValidator();

/// Avans ekleme dialog'u
///
/// Yeni avans eklemek için kullanılır.
class AddAdvanceDialog extends BaseAdvanceDialog {
  final List<Employee> employees;
  final VoidCallback onAdvanceAdded;

  const AddAdvanceDialog({
    super.key,
    required this.employees,
    required this.onAdvanceAdded,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Employee> employees,
    required VoidCallback onAdvanceAdded,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AddAdvanceDialog(
        employees: employees,
        onAdvanceAdded: onAdvanceAdded,
      ),
    );
  }

  @override
  BaseAdvanceDialogState<BaseAdvanceDialog> createState() =>
      _AddAdvanceDialogState();
}

class _AddAdvanceDialogState extends BaseAdvanceDialogState<AddAdvanceDialog> {
  final AdvanceController _controller = AdvanceController();
  Employee? _selectedEmployee;

  @override
  void initializeControllers() {
    amountController = TextEditingController();
    descriptionController = TextEditingController();
  }

  @override
  DateTime getInitialDate() => DateTime.now();

  @override
  String getTitle() => 'Avans Ekle';

  @override
  IconData getIcon() => Icons.account_balance_wallet;

  @override
  String getSaveButtonText() => 'Kaydet';

  @override
  Widget buildWorkerSelection(ThemeData theme, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Çalışan',
          style: TextStyle(
            fontSize: w * 0.035,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: w * 0.02),
        DropdownButtonFormField<Employee>(
          value: _selectedEmployee,
          decoration: InputDecoration(
            hintText: 'Çalışan seçin',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: w * 0.04,
              vertical: w * 0.035,
            ),
          ),
          items: widget.employees.map((emp) {
            return DropdownMenuItem(value: emp, child: Text(emp.name));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedEmployee = value;
            });
          },
          validator: _validator.validateEmployee,
        ),
      ],
    );
  }

  @override
  Future<void> performSave() async {
    if (_selectedEmployee == null) {
      AdvanceSnackbarHelper.showError(context, 'Lütfen bir çalışan seçin');
      return;
    }

    final advance = Advance(
      id: null,
      userId: 0,
      workerId: _selectedEmployee!.id,
      amount: double.parse(amountController.text.replaceAll('.', '')),
      advanceDate: selectedDate,
      description: descriptionController.text.trim(),
      isDeducted: false,
      deductedFromPaymentId: null,
    );

    await _controller.addAdvance(advance);

    if (!mounted) return;

    Navigator.of(context).pop();
    widget.onAdvanceAdded();

    AdvanceSnackbarHelper.showSuccess(
      context,
      '${_selectedEmployee!.name} için avans eklendi',
    );
  }
}
