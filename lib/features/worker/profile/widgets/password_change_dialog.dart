import 'package:flutter/material.dart';
import 'password_change_dialog/widgets/password_dialog_header.dart';
import 'password_change_dialog/widgets/password_dialog_footer.dart';
import 'password_change_dialog/widgets/password_text_field.dart';

/// Şifre değiştirme dialog'u
///
/// Mevcut şifre, yeni şifre ve şifre tekrarı alanları içerir.
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              PasswordDialogHeader(
                isChanging: widget.isChanging,
                onCancel: widget.onCancel,
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PasswordTextField(
                        controller: widget.currentPasswordController,
                        labelText: 'Mevcut Şifre',
                        prefixIcon: Icons.lock,
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      PasswordTextField(
                        controller: widget.newPasswordController,
                        labelText: 'Yeni Şifre (En az 6 karakter)',
                        prefixIcon: Icons.lock_outline,
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      PasswordTextField(
                        controller: widget.confirmPasswordController,
                        labelText: 'Yeni Şifre (Tekrar)',
                        prefixIcon: Icons.lock_outline,
                      ),
                    ],
                  ),
                ),
              ),
              PasswordDialogFooter(
                isChanging: widget.isChanging,
                onCancel: widget.onCancel,
                onChangePassword: widget.onChangePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
