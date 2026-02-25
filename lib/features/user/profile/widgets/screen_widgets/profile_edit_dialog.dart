import 'package:flutter/material.dart';

/// Profil düzenleme dialog widget'ı
class ProfileEditDialog extends StatefulWidget {
  final TextEditingController usernameController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController jobTitleController;
  final String? usernameError;
  final Future<void> Function() onSave;
  final VoidCallback onCancel;

  const ProfileEditDialog({
    super.key,
    required this.usernameController,
    required this.firstNameController,
    required this.lastNameController,
    required this.jobTitleController,
    this.usernameError,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Profili Düzenle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widget.usernameController,
              decoration: InputDecoration(
                labelText: 'Kullanıcı Adı',
                prefixIcon: Icon(Icons.person, color: colorScheme.primary),
                errorText: widget.usernameError,
                filled: true,
                fillColor: isDark
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.error, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.firstNameController,
              decoration: InputDecoration(
                labelText: 'Ad',
                prefixIcon: Icon(Icons.badge, color: colorScheme.primary),
                filled: true,
                fillColor: isDark
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.lastNameController,
              decoration: InputDecoration(
                labelText: 'Soyad',
                prefixIcon: Icon(Icons.badge, color: colorScheme.primary),
                filled: true,
                fillColor: isDark
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.jobTitleController,
              decoration: InputDecoration(
                labelText: 'Ünvan',
                prefixIcon: Icon(Icons.work, color: colorScheme.primary),
                filled: true,
                fillColor: isDark
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : widget.onCancel,
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isSaving
              ? null
              : () async {
                  setState(() => _isSaving = true);
                  await widget.onSave();
                  if (mounted) {
                    setState(() => _isSaving = false);
                  }
                },
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}
