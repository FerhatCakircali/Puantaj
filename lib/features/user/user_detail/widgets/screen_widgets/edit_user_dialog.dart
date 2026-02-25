import 'package:flutter/material.dart';

/// Kullanıcı düzenleme dialog widget'ı
class EditUserDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isUpdating;
  final Future<void> Function({
    required String username,
    required String firstName,
    required String lastName,
    required String jobTitle,
    required bool isAdmin,
  })
  onUpdate;

  const EditUserDialog({
    super.key,
    required this.user,
    required this.isUpdating,
    required this.onUpdate,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final TextEditingController usernameController;
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController jobTitleController;
  late bool isAdmin;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.user['username']);
    firstNameController = TextEditingController(
      text: widget.user['first_name'],
    );
    lastNameController = TextEditingController(text: widget.user['last_name']);
    jobTitleController = TextEditingController(text: widget.user['job_title']);
    isAdmin = widget.user['is_admin'] == 1;
  }

  @override
  void dispose() {
    usernameController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    jobTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Kullanıcıyı Düzenle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Kullanıcı Adı',
                prefixIcon: Icon(Icons.person, color: colorScheme.primary),
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
              controller: firstNameController,
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
              controller: lastNameController,
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
              controller: jobTitleController,
              decoration: InputDecoration(
                labelText: 'Yapılan İş',
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
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Admin Yetkisi'),
              subtitle: const Text('Bu kullanıcıya admin yetkisi ver'),
              value: isAdmin,
              onChanged: (value) {
                setState(() {
                  isAdmin = value;
                });
              },
              activeColor: Colors.white,
              activeTrackColor: colorScheme.primary,
              inactiveThumbColor: isDark ? Colors.grey.shade300 : Colors.white,
              inactiveTrackColor: isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade400,
              trackOutlineColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.transparent;
                }
                return isDark ? Colors.grey.shade600 : Colors.grey.shade500;
              }),
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
          onPressed: widget.isUpdating
              ? null
              : () async {
                  await widget.onUpdate(
                    username: usernameController.text.trim(),
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    jobTitle: jobTitleController.text.trim(),
                    isAdmin: isAdmin,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
          child: widget.isUpdating
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
