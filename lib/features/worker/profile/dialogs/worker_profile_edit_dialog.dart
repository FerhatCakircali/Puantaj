import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/dialogs/profile_edit/base_profile_edit_dialog.dart';
import '../../../../shared/dialogs/profile_edit/controllers/profile_edit_controller.dart';
import '../../../../shared/dialogs/profile_edit/models/profile_field_config.dart';

/// Çalışan profil düzenleme dialog'u
///
/// Worker rolü için profil düzenleme formu
class WorkerProfileEditDialog extends BaseProfileEditDialog {
  final int workerId;
  final String username;
  final String fullName;
  final String? title;
  final String? phone;
  final String? email;
  final Future<void> Function({
    required String username,
    required String fullName,
    String? title,
    String? phone,
    String? email,
  })
  onSaveCallback;

  const WorkerProfileEditDialog({
    super.key,
    required this.workerId,
    required this.username,
    required this.fullName,
    this.title,
    this.phone,
    this.email,
    required this.onSaveCallback,
  });

  @override
  State<WorkerProfileEditDialog> createState() =>
      _WorkerProfileEditDialogState();
}

class _WorkerProfileEditDialogState
    extends BaseProfileEditDialogState<WorkerProfileEditDialog> {
  static const String _usernameKey = 'username';
  static const String _fullNameKey = 'fullName';
  static const String _titleKey = 'title';
  static const String _phoneKey = 'phone';
  static const String _emailKey = 'email';

  @override
  ProfileEditController createController() {
    return ProfileEditController(
      workerId: widget.workerId,
      initialUsername: widget.username,
      initialEmail: widget.email,
    );
  }

  @override
  String getUsernameFieldKey() => _usernameKey;

  @override
  String? getEmailFieldKey() => _emailKey;

  @override
  List<ProfileFieldEntry> getFieldEntries() {
    return [
      ProfileFieldEntry(
        key: _usernameKey,
        config: const ProfileFieldConfig(
          label: 'Kullanıcı Adı',
          hint: 'En az 3 karakter',
          icon: Icons.account_circle_outlined,
          maxLength: 30,
          isRequired: true,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
        ),
        initialValue: widget.username,
      ),
      ProfileFieldEntry(
        key: _fullNameKey,
        config: const ProfileFieldConfig(
          label: 'Ad Soyad',
          icon: Icons.person_outline,
          maxLength: 50,
          isRequired: true,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
        ),
        initialValue: widget.fullName,
      ),
      ProfileFieldEntry(
        key: _titleKey,
        config: const ProfileFieldConfig(
          label: 'Yapılan İş',
          icon: Icons.work_outline,
          maxLength: 30,
          isRequired: false,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
        ),
        initialValue: widget.title ?? '',
      ),
      ProfileFieldEntry(
        key: _phoneKey,
        config: const ProfileFieldConfig(
          label: 'Telefon',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          maxLength: 15,
          isRequired: false,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
        ),
        initialValue: widget.phone ?? '',
      ),
      ProfileFieldEntry(
        key: _emailKey,
        config: const ProfileFieldConfig(
          label: 'E-posta Adresi',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          isRequired: true,
        ),
        initialValue: widget.email ?? '',
      ),
    ];
  }

  @override
  Future<void> onSave() async {
    final titleValue = textControllers[_titleKey]!.text.trim();
    final phoneValue = textControllers[_phoneKey]!.text.trim();

    await widget.onSaveCallback(
      username: textControllers[_usernameKey]!.text.trim(),
      fullName: textControllers[_fullNameKey]!.text.trim(),
      title: titleValue.isEmpty ? null : titleValue,
      phone: phoneValue.isEmpty ? null : phoneValue,
      email: textControllers[_emailKey]!.text.trim(),
    );
  }
}
