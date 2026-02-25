import 'package:flutter/material.dart';
import '../../../../../services/auth_service.dart';

class UserEditDialogFooter extends StatelessWidget {
  final Map<String, dynamic> user;
  final AuthService authService;
  final TextEditingController usernameController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController jobTitleController;
  final bool isAdmin;
  final bool isBlocked;

  const UserEditDialogFooter({
    super.key,
    required this.user,
    required this.authService,
    required this.usernameController,
    required this.firstNameController,
    required this.lastNameController,
    required this.jobTitleController,
    required this.isAdmin,
    required this.isBlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('İptal'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _handleSave(context),
              icon: const Icon(Icons.save),
              label: const Text('Kaydet'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave(BuildContext context) async {
    if (!context.mounted) return;

    // Alan doğrulama
    if (usernameController.text.trim().isEmpty ||
        firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty) {
      _showSnackBar(context, 'Lütfen zorunlu alanları doldurunuz.', Colors.red);
      return;
    }

    try {
      // Kullanıcı güncelleme işlemi
      final error = await authService.updateUser(
        userId: user['id'],
        username: usernameController.text.trim(),
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        jobTitle: jobTitleController.text.trim(),
        isAdmin: isAdmin,
      );

      // Engelleme durumunu ayrı olarak güncelle
      if (error == null) {
        final blockError = await authService.updateUserBlockedStatus(
          user['id'],
          isBlocked,
        );

        if (blockError != null && context.mounted) {
          _showSnackBar(
            context,
            'Engelleme durumu güncellenemedi: $blockError',
            Colors.orange,
          );
        }
      }

      if (!context.mounted) return;

      if (error != null) {
        _showSnackBar(context, error, Colors.red);
      } else {
        _showSnackBar(
          context,
          'Kullanıcı başarıyla güncellendi.',
          Colors.green,
        );
        // Dialog'u kapat ve true döndür (yenileme için)
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Hata: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
