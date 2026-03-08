import 'package:flutter/material.dart';
import '../../../../models/expense.dart';
import '../controllers/expense_controller.dart';
import 'constants/expense_dialog_constants.dart';
import 'widgets/expense_dialog_header.dart';
import 'widgets/expense_form_fields.dart';
import 'widgets/expense_dialog_footer.dart';
import 'helpers/expense_validator.dart';
import 'helpers/expense_snackbar_helper.dart';

final _validator = ExpenseFormValidator();

/// Masraf dialog'ları için base sınıf
///
/// Add ve Edit dialog'ları için ortak mantığı sağlar.
abstract class BaseExpenseDialog extends StatefulWidget {
  const BaseExpenseDialog({super.key});
}

abstract class BaseExpenseDialogState<T extends BaseExpenseDialog>
    extends State<T> {
  final ExpenseController controller = ExpenseController();
  final formKey = GlobalKey<FormState>();

  late final TextEditingController expenseTypeController;
  late final TextEditingController amountController;
  late final TextEditingController descriptionController;

  ExpenseCategory selectedCategory = ExpenseCategory.malzeme;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    initializeControllers();
  }

  @override
  void dispose() {
    expenseTypeController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  /// Controller'ları başlatır (alt sınıflar override edebilir)
  void initializeControllers() {
    expenseTypeController = TextEditingController();
    amountController = TextEditingController();
    descriptionController = TextEditingController();
  }

  /// Dialog başlık icon'u (alt sınıflar override etmeli)
  IconData get headerIcon;

  /// Dialog başlık metni (alt sınıflar override etmeli)
  String get headerTitle;

  /// Submit buton metni (alt sınıflar override etmeli)
  String get submitButtonText;

  /// Form submit işlemi (alt sınıflar override etmeli)
  Future<void> onSubmit();

  /// Tarih seçici gösterir
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

  /// Form validasyonu ve submit işlemi
  Future<void> handleSubmit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await onSubmit();

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Masraf işlem hatası: $e');

      if (!mounted) return;

      setState(() => isLoading = false);

      ExpenseSnackbarHelper.showError(context, e.toString());
    }
  }

  /// Expense nesnesi oluşturur
  Expense createExpense({int? id}) {
    return Expense(
      id: id,
      userId: 0,
      expenseType: expenseTypeController.text.trim(),
      category: selectedCategory,
      amount: _validator.parseAmountField(amountController.text),
      expenseDate: selectedDate,
      description: descriptionController.text.trim(),
      receiptUrl: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(w * 0.06),
        constraints: const BoxConstraints(
          maxWidth: ExpenseDialogConstants.maxDialogWidth,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExpenseDialogHeader(
                  icon: headerIcon,
                  title: headerTitle,
                  onClose: () => Navigator.of(context).pop(),
                ),
                SizedBox(height: w * 0.06),
                ExpenseFormFields(
                  expenseTypeController: expenseTypeController,
                  amountController: amountController,
                  descriptionController: descriptionController,
                  selectedCategory: selectedCategory,
                  selectedDate: selectedDate,
                  onCategoryChanged: (category) {
                    setState(() => selectedCategory = category);
                  },
                  onDateTap: selectDate,
                ),
                SizedBox(height: w * 0.06),
                ExpenseDialogFooter(
                  isLoading: isLoading,
                  onCancel: () => Navigator.of(context).pop(),
                  onSubmit: handleSubmit,
                  submitButtonText: submitButtonText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
