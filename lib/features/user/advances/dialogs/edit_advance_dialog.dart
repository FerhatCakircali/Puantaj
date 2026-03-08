import 'package:flutter/material.dart';
import '../../../../models/advance.dart';
import '../controllers/advance_controller.dart';
import 'base_advance_dialog.dart';
import 'helpers/advance_snackbar_helper.dart';

/// Avans düzenleme dialog'u
///
/// Mevcut avansı düzenlemek için kullanılır.
class EditAdvanceDialog extends BaseAdvanceDialog {
  final Advance advance;
  final String workerName;
  final VoidCallback onAdvanceUpdated;

  const EditAdvanceDialog({
    super.key,
    required this.advance,
    required this.workerName,
    required this.onAdvanceUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required Advance advance,
    required String workerName,
    required VoidCallback onAdvanceUpdated,
  }) {
    return showDialog(
      context: context,
      builder: (context) => EditAdvanceDialog(
        advance: advance,
        workerName: workerName,
        onAdvanceUpdated: onAdvanceUpdated,
      ),
    );
  }

  @override
  BaseAdvanceDialogState<BaseAdvanceDialog> createState() =>
      _EditAdvanceDialogState();
}

class _EditAdvanceDialogState
    extends BaseAdvanceDialogState<EditAdvanceDialog> {
  final AdvanceController _controller = AdvanceController();

  @override
  void initializeControllers() {
    amountController = TextEditingController(
      text: widget.advance.amount.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      ),
    );
    descriptionController = TextEditingController(
      text: widget.advance.description ?? '',
    );
  }

  @override
  DateTime getInitialDate() => widget.advance.advanceDate;

  @override
  String getTitle() => 'Avans Düzenle';

  @override
  IconData getIcon() => Icons.edit;

  @override
  String getSaveButtonText() => 'Güncelle';

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
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.04,
            vertical: w * 0.035,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            widget.workerName,
            style: TextStyle(
              fontSize: w * 0.04,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Future<void> performSave() async {
    final updatedAdvance = widget.advance.copyWith(
      amount: double.parse(amountController.text.replaceAll('.', '')),
      advanceDate: selectedDate,
      description: descriptionController.text.trim(),
    );

    await _controller.updateAdvance(updatedAdvance);

    if (!mounted) return;

    Navigator.of(context).pop();
    widget.onAdvanceUpdated();

    AdvanceSnackbarHelper.showSuccess(context, 'Avans güncellendi');
  }
}
