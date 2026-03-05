import 'package:flutter/material.dart';

/// Şifre değiştirme dialog'u
/// Mevcut şifre, yeni şifre ve şifre tekrarı alanları içerir
class PasswordChangeDialog extends StatefulWidget {
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool isChanging;
  final Future<void> Function() onChangePassword;
  final VoidCallback onCancel;

  const PasswordChangeDialog({
    super.key,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.isChanging,
    required this.onChangePassword,
    required this.onCancel,
  });

  @override
  State<PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<PasswordChangeDialog> {
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Dialog(
        backgroundColor: isDark ? const Color(0xFF0A0E1A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: screenWidth * 1.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Row(
                  children: [
                    Container(
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
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Text(
                        'Şifre Değiştir',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : colorScheme.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.isChanging ? null : widget.onCancel,
                      icon: Icon(
                        Icons.close,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.grey.shade700,
                        size: screenWidth * 0.06,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCurrentPasswordField(
                        colorScheme,
                        isDark,
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      _buildNewPasswordField(colorScheme, isDark, screenWidth),
                      SizedBox(height: screenWidth * 0.04),
                      _buildConfirmPasswordField(
                        colorScheme,
                        isDark,
                        screenWidth,
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Actions
              Container(
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
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.isChanging ? null : widget.onCancel,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: screenWidth * 0.035,
                          ),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.02,
                            ),
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
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: FilledButton(
                        onPressed: widget.isChanging
                            ? null
                            : widget.onChangePassword,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          padding: EdgeInsets.symmetric(
                            vertical: screenWidth * 0.035,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.02,
                            ),
                          ),
                        ),
                        child: widget.isChanging
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
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPasswordField(
    ColorScheme colorScheme,
    bool isDark,
    double screenWidth,
  ) {
    return TextField(
      controller: widget.currentPasswordController,
      decoration: InputDecoration(
        labelText: 'Mevcut Şifre',
        prefixIcon: Icon(
          Icons.lock,
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : colorScheme.primary,
          size: screenWidth * 0.055,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _showCurrentPassword ? Icons.visibility : Icons.visibility_off,
            size: screenWidth * 0.055,
          ),
          onPressed: () =>
              setState(() => _showCurrentPassword = !_showCurrentPassword),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      style: TextStyle(fontSize: screenWidth * 0.038),
      obscureText: !_showCurrentPassword,
    );
  }

  Widget _buildNewPasswordField(
    ColorScheme colorScheme,
    bool isDark,
    double screenWidth,
  ) {
    return TextField(
      controller: widget.newPasswordController,
      decoration: InputDecoration(
        labelText: 'Yeni Şifre (En az 6 karakter)',
        prefixIcon: Icon(
          Icons.lock_outline,
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : colorScheme.primary,
          size: screenWidth * 0.055,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _showNewPassword ? Icons.visibility : Icons.visibility_off,
            size: screenWidth * 0.055,
          ),
          onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      style: TextStyle(fontSize: screenWidth * 0.038),
      obscureText: !_showNewPassword,
    );
  }

  Widget _buildConfirmPasswordField(
    ColorScheme colorScheme,
    bool isDark,
    double screenWidth,
  ) {
    return TextField(
      controller: widget.confirmPasswordController,
      decoration: InputDecoration(
        labelText: 'Yeni Şifre (Tekrar)',
        prefixIcon: Icon(
          Icons.lock_outline,
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : colorScheme.primary,
          size: screenWidth * 0.055,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
            size: screenWidth * 0.055,
          ),
          onPressed: () =>
              setState(() => _showConfirmPassword = !_showConfirmPassword),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      style: TextStyle(fontSize: screenWidth * 0.038),
      obscureText: !_showConfirmPassword,
    );
  }
}
