import 'package:flutter/material.dart';

/// Dialog action buttons widget'ı
///
/// Kaydet ve iptal butonlarını içerir.
class DialogActions extends StatelessWidget {
  final double screenWidth;
  final ColorScheme colorScheme;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String saveLabel;
  final IconData saveIcon;
  final bool isProcessing;
  final String? processingLabel;

  const DialogActions({
    super.key,
    required this.screenWidth,
    required this.colorScheme,
    required this.onSave,
    required this.onCancel,
    required this.saveLabel,
    this.saveIcon = Icons.save,
    this.isProcessing = false,
    this.processingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.06),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: isProcessing ? null : onSave,
                icon: isProcessing
                    ? SizedBox(
                        width: screenWidth * 0.045,
                        height: screenWidth * 0.045,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(saveIcon, size: screenWidth * 0.045),
                label: Text(
                  isProcessing
                      ? (processingLabel ?? 'İşleniyor...')
                      : saveLabel,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.03),
              TextButton(
                onPressed: isProcessing ? null : onCancel,
                child: const Text('İptal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
