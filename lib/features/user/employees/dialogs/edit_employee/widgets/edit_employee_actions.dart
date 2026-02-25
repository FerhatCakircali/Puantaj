import 'package:flutter/material.dart';

/// Dialog aksiyon butonları widget'ı
class EditEmployeeActions extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool isProcessing;

  const EditEmployeeActions({
    super.key,
    required this.onSave,
    required this.onCancel,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: isProcessing ? null : onSave,
            icon: isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save, size: 18),
            label: Text(
              isProcessing ? 'Kaydediliyor...' : 'Değişiklikleri Kaydet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: isProcessing ? null : onCancel,
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }
}
