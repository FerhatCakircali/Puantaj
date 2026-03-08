import 'package:flutter/material.dart';
import '../constants/expense_dialog_constants.dart';

/// Masraf dialog alt buton widget'ı
///
/// İptal ve kaydet/güncelle butonlarını içerir.
class ExpenseDialogFooter extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String submitButtonText;

  const ExpenseDialogFooter({
    super.key,
    required this.isLoading,
    required this.onCancel,
    required this.onSubmit,
    required this.submitButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : onCancel,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: w * 0.035),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ExpenseDialogConstants.borderRadius,
                ),
              ),
            ),
            child: const Text('İptal'),
          ),
        ),
        SizedBox(width: w * 0.03),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: ExpenseDialogConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: w * 0.035),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ExpenseDialogConstants.borderRadius,
                ),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    height: w * 0.05,
                    width: w * 0.05,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(submitButtonText),
          ),
        ),
      ],
    );
  }
}
