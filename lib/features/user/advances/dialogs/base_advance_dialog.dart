import 'package:flutter/material.dart';
import 'widgets/advance_dialog_header.dart';
import 'widgets/advance_dialog_footer.dart';
import 'widgets/advance_form_fields.dart';

/// Avans dialog base sınıfı
///
/// Add ve Edit dialog'ların ortak mantığını içerir.
abstract class BaseAdvanceDialog extends StatefulWidget {
  const BaseAdvanceDialog({super.key});

  @override
  BaseAdvanceDialogState createState();
}

abstract class BaseAdvanceDialogState<T extends BaseAdvanceDialog>
    extends State<T> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController amountController;
  late TextEditingController descriptionController;
  late DateTime selectedDate;
  bool isLoading = false;

  static const Color primaryColor = Color(0xFF4338CA);

  @override
  void initState() {
    super.initState();
    initializeControllers();
    selectedDate = getInitialDate();
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  /// Controller'ları başlat
  void initializeControllers();

  /// Başlangıç tarihini döndür
  DateTime getInitialDate();

  /// Dialog başlığını döndür
  String getTitle();

  /// Dialog ikonunu döndür
  IconData getIcon();

  /// Kaydet butonu metnini döndür
  String getSaveButtonText();

  /// Worker/Employee seçim widget'ını döndür
  Widget buildWorkerSelection(ThemeData theme, double w);

  /// Kaydetme işlemini gerçekleştir
  Future<void> performSave();

  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> handleSave() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await performSave();
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = MediaQuery.sizeOf(context).width;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(w * 0.06),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdvanceDialogHeader(
                  title: getTitle(),
                  icon: getIcon(),
                  primaryColor: primaryColor,
                ),
                SizedBox(height: w * 0.06),
                buildWorkerSelection(theme, w),
                SizedBox(height: w * 0.04),
                AdvanceFormFields(
                  amountController: amountController,
                  descriptionController: descriptionController,
                  selectedDate: selectedDate,
                  onDateTap: selectDate,
                ),
                SizedBox(height: w * 0.06),
                AdvanceDialogFooter(
                  isLoading: isLoading,
                  onCancel: () => Navigator.of(context).pop(),
                  onSave: handleSave,
                  saveButtonText: getSaveButtonText(),
                  primaryColor: primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
