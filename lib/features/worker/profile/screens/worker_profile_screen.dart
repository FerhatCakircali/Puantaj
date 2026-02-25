import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/mixins/context_safety_mixin.dart';
import '../mixins/worker_profile_data_mixin.dart';
import '../mixins/worker_password_mixin.dart';
import '../widgets/worker_profile_widgets.dart';

/// Çalışan profil ekranı
///
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
      debugPrint('❌ Worker is null, cannot edit profile');
      return;
    }

    debugPrint('✅ Opening profile edit dialog for: ${worker!.fullName}');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ProfileEditDialog(
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
              await updateWorkerProfile(
                username: username,
                fullName: fullName,
                title: title,
                phone: phone,
                email: email,
              );
            },
      ),
    );

    if (result == true && mounted) {
      debugPrint('✅ Profile updated, reloading data');
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
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (worker == null) {
      return const Center(child: Text('Profil bilgileri yüklenemedi'));
    }

    debugPrint('🔍 Building profile with: ${worker!.fullName}, $username');

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ProfileAvatarCard(
              fullName: worker!.fullName,
              title: worker!.title,
              isTablet: false,
            ),
            SizedBox(height: screenWidth * 0.04),
            ProfileInfoCard(
              username: username ?? '',
              fullName: worker!.fullName,
              title: worker!.title,
              phone: worker!.phone,
              email: worker!.email,
              isTablet: false,
              onEdit: _handleProfileEdit,
            ),
            SizedBox(height: screenWidth * 0.04),
            PasswordCard(
              isTablet: false,
              onChangePassword: _showChangePasswordDialog,
            ),
          ],
        ),
      ),
    );
  }
}
