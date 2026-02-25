import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';

/// Şifre değiştirme dialog widget'ı
class PasswordChangeDialog extends StatefulWidget {
  final AuthService authService;

  const PasswordChangeDialog({super.key, required this.authService});

  @override
  State<PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<PasswordChangeDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isChangingPassword = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!mounted) return;

    setState(() => _isChangingPassword = true);

    try {
      final error = await widget.authService.changePassword(
        _currentPasswordController.text.trim(),
        _newPasswordController.text.trim(),
      );

      if (!mounted) return;

      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Şifre başarıyla değiştirildi.')),
          );
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          Navigator.pop(context);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
      title: Column(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).primaryColor.withValues(alpha: 0.1),
            radius: 28,
            child: Icon(
              Icons.lock_outline,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Şifre Değiştir',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _currentPasswordController,
              decoration: InputDecoration(
                labelText: 'Mevcut Şifre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showCurrentPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () => setState(
                    () => _showCurrentPassword = !_showCurrentPassword,
                  ),
                ),
              ),
              obscureText: !_showCurrentPassword,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: 'Yeni Şifre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNewPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _showNewPassword = !_showNewPassword),
                ),
              ),
              obscureText: !_showNewPassword,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Yeni Şifre (Tekrar)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () => setState(
                    () => _showConfirmPassword = !_showConfirmPassword,
                  ),
                ),
              ),
              obscureText: !_showConfirmPassword,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isChangingPassword
              ? null
              : () async {
                  if (!mounted) return;

                  if (_currentPasswordController.text.trim().isEmpty ||
                      _newPasswordController.text.trim().isEmpty ||
                      _confirmPasswordController.text.trim().isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Lütfen tüm şifre alanlarını doldurunuz.',
                          ),
                        ),
                      );
                    }
                    return;
                  }
                  if (_newPasswordController.text.trim() !=
                      _confirmPasswordController.text.trim()) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Yeni şifreler eşleşmiyor.'),
                        ),
                      );
                    }
                    return;
                  }

                  await _changePassword();
                },
          child: _isChangingPassword
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : const Text('Değiştir'),
        ),
      ],
    );
  }
}
