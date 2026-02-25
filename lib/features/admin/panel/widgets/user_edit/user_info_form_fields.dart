import 'package:flutter/material.dart';

class UserInfoFormFields extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController jobTitleController;

  const UserInfoFormFields({
    super.key,
    required this.usernameController,
    required this.firstNameController,
    required this.lastNameController,
    required this.jobTitleController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(context, 'Kullanıcı Bilgileri', Icons.person),
        const SizedBox(height: 16),
        _buildModernTextField(
          context: context,
          controller: usernameController,
          label: 'Kullanıcı Adı',
          icon: Icons.alternate_email,
          hint: 'Kullanıcı adını girin',
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          context: context,
          controller: firstNameController,
          label: 'Ad',
          icon: Icons.person_outline,
          hint: 'Adını girin',
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          context: context,
          controller: lastNameController,
          label: 'Soyad',
          icon: Icons.person_outline,
          hint: 'Soyadını girin',
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          context: context,
          controller: jobTitleController,
          label: 'Meslek',
          icon: Icons.work_outline,
          hint: 'Mesleğini girin',
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2.5,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
