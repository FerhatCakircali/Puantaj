import 'package:flutter/material.dart';
import '../../../../../screens/constants/colors.dart';

/// Şifre değiştirme dialog widget'ı
class ProfilePasswordDialog extends StatefulWidget {
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final Future<void> Function() onChangePassword;
  final VoidCallback onCancel;

  const ProfilePasswordDialog({
    super.key,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.onChangePassword,
    required this.onCancel,
  });

  @override
  State<ProfilePasswordDialog> createState() => _ProfilePasswordDialogState();
}

class _ProfilePasswordDialogState extends State<ProfilePasswordDialog> {
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isChanging = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

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
                        color: primaryIndigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        color: primaryIndigo,
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
                          color: isDark ? Colors.white : primaryIndigo,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onCancel,
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
                      _buildPasswordField(
                        controller: widget.currentPasswordController,
                        label: 'Mevcut Şifre',
                        icon: Icons.lock,
                        isVisible: _showCurrentPassword,
                        onToggleVisibility: () => setState(
                          () => _showCurrentPassword = !_showCurrentPassword,
                        ),
                        isDark: isDark,
                        screenWidth: screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      _buildPasswordField(
                        controller: widget.newPasswordController,
                        label: 'Yeni Şifre (En az 6 karakter)',
                        icon: Icons.lock_outline,
                        isVisible: _showNewPassword,
                        onToggleVisibility: () => setState(
                          () => _showNewPassword = !_showNewPassword,
                        ),
                        isDark: isDark,
                        screenWidth: screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      _buildPasswordField(
                        controller: widget.confirmPasswordController,
                        label: 'Yeni Şifre (Tekrar)',
                        icon: Icons.lock_outline,
                        isVisible: _showConfirmPassword,
                        onToggleVisibility: () => setState(
                          () => _showConfirmPassword = !_showConfirmPassword,
                        ),
                        isDark: isDark,
                        screenWidth: screenWidth,
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
                        onPressed: _isChanging ? null : widget.onCancel,
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
                        onPressed: _isChanging
                            ? null
                            : () async {
                                if (!mounted) return;

                                // Şifre doğrulama
                                if (widget.currentPasswordController.text
                                        .trim()
                                        .isEmpty ||
                                    widget.newPasswordController.text
                                        .trim()
                                        .isEmpty ||
                                    widget.confirmPasswordController.text
                                        .trim()
                                        .isEmpty) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Lütfen tüm şifre alanlarını doldurunuz.',
                                        ),
                                        backgroundColor: errorColor,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            screenWidth * 0.02,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                }

                                // Şifre uzunluk kontrolü
                                if (widget.newPasswordController.text
                                        .trim()
                                        .length <
                                    6) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Yeni şifre en az 6 karakter olmalıdır.',
                                        ),
                                        backgroundColor: errorColor,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            screenWidth * 0.02,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                }

                                if (widget.newPasswordController.text.trim() !=
                                    widget.confirmPasswordController.text
                                        .trim()) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Yeni şifreler eşleşmiyor.',
                                        ),
                                        backgroundColor: errorColor,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            screenWidth * 0.02,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                }

                                setState(() => _isChanging = true);
                                await widget.onChangePassword();
                                if (mounted) {
                                  setState(() => _isChanging = false);
                                  Navigator.pop(context);
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryIndigo,
                          padding: EdgeInsets.symmetric(
                            vertical: screenWidth * 0.035,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.02,
                            ),
                          ),
                        ),
                        child: _isChanging
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required bool isDark,
    required double screenWidth,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white.withValues(alpha: 0.7) : primaryIndigo,
          size: screenWidth * 0.055,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            size: screenWidth * 0.055,
          ),
          onPressed: onToggleVisibility,
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
          borderSide: const BorderSide(color: primaryIndigo, width: 2),
        ),
      ),
      style: TextStyle(fontSize: screenWidth * 0.038),
      obscureText: !isVisible,
    );
  }
}
