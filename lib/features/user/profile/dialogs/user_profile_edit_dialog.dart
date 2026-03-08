import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/dialogs/profile_edit/base_profile_edit_dialog.dart';
import '../../../../shared/dialogs/profile_edit/controllers/profile_edit_controller.dart';
import '../../../../shared/dialogs/profile_edit/models/profile_field_config.dart';

/// Kullanıcı profil düzenleme dialog'u
///
/// User rolü için profil düzenleme formu
class UserProfileEditDialog extends BaseProfileEditDialog {
  final int userId;
  final String username;
  final String firstName;
  final String lastName;
  final String jobTitle;
  final String email;
  final Future<void> Function({
    required String username,
    required String firstName,
    required String lastName,
    required String jobTitle,
    required String email,
  })
  onSaveCallback;

  const UserProfileEditDialog({
    super.key,
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.jobTitle,
    required this.email,
    required this.onSaveCallback,
  });

  @override
  State<UserProfileEditDialog> createState() => _UserProfileEditDialogState();
}

class _UserProfileEditDialogState
    extends BaseProfileEditDialogState<UserProfileEditDialog> {
  static const String _usernameKey = 'username';
  static const String _firstNameKey = 'firstName';
  static const String _lastNameKey = 'lastName';
  static const String _jobTitleKey = 'jobTitle';
  static const String _emailKey = 'email';

  @override
  ProfileEditController createController() {
    return ProfileEditController(
      userId: widget.userId,
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
        key: _firstNameKey,
        config: const ProfileFieldConfig(
          label: 'Ad',
          icon: Icons.person_outline,
          maxLength: 30,
          isRequired: true,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
        ),
        initialValue: widget.firstName,
      ),
      ProfileFieldEntry(
        key: _lastNameKey,
        config: const ProfileFieldConfig(
          label: 'Soyad',
          icon: Icons.person_outline,
          maxLength: 30,
          isRequired: true,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
        ),
        initialValue: widget.lastName,
      ),
      ProfileFieldEntry(
        key: _jobTitleKey,
        config: const ProfileFieldConfig(
          label: 'Yapılan İş',
          icon: Icons.work_outline,
          maxLength: 30,
          isRequired: true,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
        ),
        initialValue: widget.jobTitle,
      ),
      ProfileFieldEntry(
        key: _emailKey,
        config: const ProfileFieldConfig(
          label: 'E-posta Adresi',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          isRequired: true,
        ),
        initialValue: widget.email,
      ),
    ];
  }

  @override
  Future<void> onSave() async {
    await widget.onSaveCallback(
      username: textControllers[_usernameKey]!.text.trim(),
      firstName: textControllers[_firstNameKey]!.text.trim(),
      lastName: textControllers[_lastNameKey]!.text.trim(),
      jobTitle: textControllers[_jobTitleKey]!.text.trim(),
      email: textControllers[_emailKey]!.text.trim(),
    );
  }
}
