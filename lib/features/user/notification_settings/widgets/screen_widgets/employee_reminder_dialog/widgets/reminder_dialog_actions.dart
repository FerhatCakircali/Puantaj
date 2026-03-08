import 'package:flutter/material.dart';

/// Dialog aksiyon butonları widget'ı
class ReminderDialogActions extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const ReminderDialogActions({
    super.key,
    required this.isSubmitting,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: isSubmitting ? null : onCancel,
          child: const Text('İptal'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: isSubmitting ? null : onSave,
          icon: isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save, size: 18),
          label: Text(isSubmitting ? 'Kaydediliyor...' : 'Kaydet'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }
}
