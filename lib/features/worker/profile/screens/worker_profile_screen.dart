import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/mixins/context_safety_mixin.dart';
import '../../../../shared/widgets/profile/shared_profile_avatar_card.dart';
import '../../../../shared/widgets/profile/shared_profile_info_card.dart';
import '../../../../shared/widgets/profile/shared_password_card.dart';
import '../mixins/worker_profile_data_mixin.dart';
import '../mixins/worker_password_mixin.dart';
import '../widgets/profile_edit_dialog.dart';
import '../widgets/password_change_dialog.dart';

/// Çalışan profil ekranı
/// Admin panel gibi basitleştirilmiş versiyon
class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen>
    with
        ContextSafetyMixin,
        AutomaticKeepAliveClientMixin,
        WorkerProfileDataMixin,
        WorkerPasswordMixin {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await loadWorkerData(onSessionExpired: () => context.go('/worker/login'));
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleProfileEdit() async {
    if (worker == null) {
      debugPrint('Worker is null, cannot edit profile');
      return;
    }

    if (worker!.id == null) {
      debugPrint('Worker ID is null, cannot edit profile');
      contextSafety.safeShowErrorSnackBar(
        'Profil düzenlenemedi: ID bulunamadı',
      );
      return;
    }

    debugPrint('Opening profile edit dialog for: ${worker!.fullName}');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ProfileEditDialog(
        workerId: worker!.id!,
        username: username ?? '',
        fullName: worker!.fullName,
        title: worker!.title,
        phone: worker!.phone,
        email: worker!.email,
        onSave:
            ({
              required String username,
              required String fullName,
              String? title,
              String? phone,
              String? email,
            }) async {
              debugPrint(
                '💾 Saving profile: $username, $fullName, $title, $phone, $email',
              );
              final success = await updateWorkerProfile(
                username: username,
                fullName: fullName,
                title: title,
                phone: phone,
                email: email,
              );

              // Eğer güncelleme başarısız olduysa hata fırlat
              if (!success) {
                throw Exception('Profil güncellenemedi');
              }
            },
      ),
    );

    if (result == true && mounted) {
      debugPrint('Profile updated, reloading data');
      await _loadData();
    }
  }

  Future<void> _handleChangePassword() async {
    final success = await changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (success && mounted) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => PasswordChangeDialog(
        currentPasswordController: _currentPasswordController,
        newPasswordController: _newPasswordController,
        confirmPasswordController: _confirmPasswordController,
        isChanging: isChangingPassword,
        onChangePassword: () async {
          Navigator.pop(context);
          await _handleChangePassword();
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.sizeOf(context).width;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (worker == null) {
      return const Center(child: Text('Profil bilgileri yüklenemedi'));
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SharedProfileAvatarCard(
              fullName: worker!.fullName,
              subtitle: worker!.title,
            ),
            SizedBox(height: screenWidth * 0.04),
            SharedProfileInfoCard(
              title: 'Çalışan Bilgileri',
              fields: [
                ProfileInfoField(
                  icon: Icons.person_outline,
                  label: 'Kullanıcı Adı',
                  value: username ?? '',
                ),
                ProfileInfoField(
                  icon: Icons.badge_outlined,
                  label: 'Ad Soyad',
                  value: worker!.fullName,
                ),
                if (worker!.title != null && worker!.title!.isNotEmpty)
                  ProfileInfoField(
                    icon: Icons.work_outline,
                    label: 'Yapılan İş',
                    value: worker!.title!,
                  ),
                if (worker!.phone != null && worker!.phone!.isNotEmpty)
                  ProfileInfoField(
                    icon: Icons.phone,
                    label: 'Telefon',
                    value: worker!.phone!,
                  ),
                ProfileInfoField(
                  icon: Icons.email_outlined,
                  label: 'E-posta',
                  value: worker!.email ?? '',
                ),
              ],
              onEdit: _handleProfileEdit,
            ),
            SizedBox(height: screenWidth * 0.04),
            SharedPasswordCard(onChangePassword: _showChangePasswordDialog),
          ],
        ),
      ),
    );
  }
}
