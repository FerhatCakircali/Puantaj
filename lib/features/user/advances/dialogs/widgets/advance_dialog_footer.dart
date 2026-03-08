import 'package:flutter/material.dart';

/// Avans dialog alt kısmı widget'ı
///
/// İptal ve Kaydet/Güncelle butonlarını içerir.
class AdvanceDialogFooter extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String saveButtonText;
  final Color primaryColor;

  const AdvanceDialogFooter({
    super.key,
    required this.isLoading,
    required this.onCancel,
    required this.onSave,
    required this.saveButtonText,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : onCancel,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: w * 0.035),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('İptal'),
          ),
        ),
        SizedBox(width: w * 0.03),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: w * 0.035),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                : Text(saveButtonText),
          ),
        ),
      ],
    );
  }
}
