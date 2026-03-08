import 'package:flutter/material.dart';

/// Şifre değiştirme dialog alt kısmı widget'ı
///
/// İptal ve Değiştir butonlarını içerir.
class PasswordDialogFooter extends StatelessWidget {
  final bool isChanging;
  final VoidCallback onCancel;
  final Future<void> Function() onChangePassword;

  const PasswordDialogFooter({
    super.key,
    required this.isChanging,
    required this.onCancel,
    required this.onChangePassword,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.grey.shade50,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildCancelButton(isDark, screenWidth)),
          SizedBox(width: screenWidth * 0.03),
          Expanded(child: _buildChangeButton(colorScheme, screenWidth)),
        ],
      ),
    );
  }

  Widget _buildCancelButton(bool isDark, double screenWidth) {
    return OutlinedButton(
      onPressed: isChanging ? null : onCancel,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.035),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
        ),
      ),
      child: Text(
        'İptal',
        style: TextStyle(
          fontSize: screenWidth * 0.038,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildChangeButton(ColorScheme colorScheme, double screenWidth) {
    return FilledButton(
      onPressed: isChanging ? null : onChangePassword,
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.035),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
        ),
      ),
      child: isChanging
          ? SizedBox(
              width: screenWidth * 0.04,
              height: screenWidth * 0.04,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              'Değiştir',
              style: TextStyle(
                fontSize: screenWidth * 0.038,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
    );
  }
}
