import 'package:flutter/material.dart';

/// Şifre değiştirme dialog başlığı widget'ı
///
/// Dialog'un üst kısmındaki başlık ve kapat butonunu içerir.
class PasswordDialogHeader extends StatelessWidget {
  final bool isChanging;
  final VoidCallback onCancel;

  const PasswordDialogHeader({
    super.key,
    required this.isChanging,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Row(
            children: [
              _buildIcon(colorScheme, screenWidth),
              SizedBox(width: screenWidth * 0.03),
              _buildTitle(isDark, colorScheme, screenWidth),
              _buildCloseButton(isDark, screenWidth),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.shade200,
        ),
      ],
    );
  }

  Widget _buildIcon(ColorScheme colorScheme, double screenWidth) {
    return Container(
      width: screenWidth * 0.1,
      height: screenWidth * 0.1,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
      ),
      child: Icon(
        Icons.lock_outline,
        color: colorScheme.primary,
        size: screenWidth * 0.05,
      ),
    );
  }

  Widget _buildTitle(bool isDark, ColorScheme colorScheme, double screenWidth) {
    return Expanded(
      child: Text(
        'Şifre Değiştir',
        style: TextStyle(
          fontSize: screenWidth * 0.045,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCloseButton(bool isDark, double screenWidth) {
    return IconButton(
      onPressed: isChanging ? null : onCancel,
      icon: Icon(
        Icons.close,
        color: isDark
            ? Colors.white.withValues(alpha: 0.7)
            : Colors.grey.shade700,
        size: screenWidth * 0.06,
      ),
    );
  }
}
