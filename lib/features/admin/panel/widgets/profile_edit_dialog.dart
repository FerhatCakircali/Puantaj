import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';

/// Profil düzenleme dialog widget'ı
class ProfileEditDialog extends StatelessWidget {
  final Map<String, dynamic> user;
  final AuthService authService;
  final VoidCallback onSuccess;

  const ProfileEditDialog({
    super.key,
    required this.user,
    required this.authService,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final firstNameController = TextEditingController(
      text: user['first_name'] ?? '',
    );
    final lastNameController = TextEditingController(
      text: user['last_name'] ?? '',
    );
    final usernameController = TextEditingController(
      text: user['username'] ?? '',
    );
    final jobTitleController = TextEditingController(
      text: user['job_title'] ?? '',
    );
    final emailController = TextEditingController(text: user['email'] ?? '');

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
              Icons.edit,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Profil Düzenle',
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
            _buildTextField(
              context,
              usernameController,
              'Kullanıcı Adı',
              Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context,
              firstNameController,
              'Ad',
              Icons.badge_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context,
              lastNameController,
              'Soyad',
              Icons.badge_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context,
              jobTitleController,
              'Meslek',
              Icons.work_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context,
              emailController,
              'Email Adresi',
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
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
          onPressed: () async {
            if (usernameController.text.trim().isEmpty ||
                firstNameController.text.trim().isEmpty ||
                lastNameController.text.trim().isEmpty ||
                jobTitleController.text.trim().isEmpty ||
                emailController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lütfen tüm alanları doldurunuz.'),
                ),
              );
              return;
            }

            // Email validasyonu
            final emailRegex = RegExp(
              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            );
            if (!emailRegex.hasMatch(emailController.text.trim())) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Geçerli bir email adresi girin.'),
                ),
              );
              return;
            }

            final error = await authService.updateUser(
              userId: user['id'],
              username: usernameController.text.trim(),
              firstName: firstNameController.text.trim(),
              lastName: lastNameController.text.trim(),
              jobTitle: jobTitleController.text.trim(),
              isAdmin: user['is_admin'] == 1,
              email: emailController.text.trim(),
            );

            if (!context.mounted) return;

            if (error != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(error)));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profil başarıyla güncellendi.')),
              );
              Navigator.pop(context);
              onSuccess();
            }
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context,
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
