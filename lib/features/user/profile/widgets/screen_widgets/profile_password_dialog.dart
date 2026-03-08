import 'package:flutter/material.dart';
import '../../../../../screens/constants/colors.dart';
import 'profile_password_dialog/widgets/password_dialog_header.dart';
import 'profile_password_dialog/widgets/password_dialog_footer.dart';
import 'profile_password_dialog/widgets/password_text_field.dart';
import 'profile_password_dialog/validators/password_validator.dart';

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
  bool _isChanging = false;

  Future<void> _handleSubmit() async {
    if (!mounted) return;

    final validationError = PasswordValidator.getValidationError(
      currentPassword: widget.currentPasswordController.text,
      newPassword: widget.newPasswordController.text,
      confirmPassword: widget.confirmPasswordController.text,
    );

    if (validationError != null) {
      if (!mounted) return;
      _showErrorSnackBar(validationError);
      return;
    }

    setState(() => _isChanging = true);
    await widget.onChangePassword();
    if (!mounted) return;
    setState(() => _isChanging = false);
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _showErrorSnackBar(String message) {
    final screenWidth = MediaQuery.of(context).size.width;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
        ),
      ),
    );
  }

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
              PasswordDialogHeader(onClose: widget.onCancel),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PasswordTextField(
                        controller: widget.currentPasswordController,
                        label: 'Mevcut Şifre',
                        icon: Icons.lock,
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      PasswordTextField(
                        controller: widget.newPasswordController,
                        label: 'Yeni Şifre (En az 6 karakter)',
                        icon: Icons.lock_outline,
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      PasswordTextField(
                        controller: widget.confirmPasswordController,
                        label: 'Yeni Şifre (Tekrar)',
                        icon: Icons.lock_outline,
                      ),
                    ],
                  ),
                ),
              ),
              PasswordDialogFooter(
                onCancel: widget.onCancel,
                onSubmit: _handleSubmit,
                isLoading: _isChanging,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
