import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../../../../shared/widgets/profile/shared_profile_avatar_card.dart';
import '../../../../shared/widgets/profile/shared_profile_info_card.dart';
import '../../../../shared/widgets/profile/shared_password_card.dart';
import '../dialogs/user_profile_edit_dialog.dart';
import '../widgets/screen_widgets/profile_password_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = true;

  // User data
  int? _userId;
  String? _username;
  String? _firstName;
  String? _lastName;
  String? _jobTitle;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.currentUser;

      if (!mounted) return;

      setState(() {
        _userId = user?['id'] as int?;
        _username = user?['username'] as String?;
        _firstName = user?['first_name'] as String?;
        _lastName = user?['last_name'] as String?;
        _jobTitle = user?['job_title'] as String?;
        _email = user?['email'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Kullanıcı bilgileri yüklenirken hata: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleProfileEdit() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgileri yüklenemedi')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => UserProfileEditDialog(
        userId: _userId!,
        username: _username ?? '',
        firstName: _firstName ?? '',
        lastName: _lastName ?? '',
        jobTitle: _jobTitle ?? '',
        email: _email ?? '',
        onSaveCallback:
            ({
              required String username,
              required String firstName,
              required String lastName,
              required String jobTitle,
              required String email,
            }) async {
              // Kullanıcı adı değiştiyse güncelle
              if (username.toLowerCase() != _username?.toLowerCase()) {
                final usernameError = await _authService.updateUsername(
                  username,
                );
                if (usernameError != null) {
                  throw Exception(usernameError);
                }
              }

              // Diğer bilgileri güncelle
              final error = await _authService.updateProfile(
                firstName,
                lastName,
                jobTitle,
                email: email,
              );

              if (error != null) {
                throw Exception(error);
              }
            },
      ),
    );

    if (result == true && mounted) {
      await _loadUserData();
    }
  }

  Future<void> _changePassword() async {
    if (!mounted) return;

    // Alan doğrulama
    if (_currentPasswordController.text.trim().isEmpty ||
        _newPasswordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen tüm şifre alanlarını doldurunuz.'),
          ),
        );
      }
      return; // Boş alan varsa işlemi durdur
    }

    if (_newPasswordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      // Şifreleri trimleyerek karşılaştır
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni şifreler eşleşmiyor.')),
      );
      return; // Şifreler eşleşmiyorsa işlemi durdur
    }

    try {
      final error = await _authService.changePassword(
        _currentPasswordController.text.trim(), // Boşlukları temizle
        _newPasswordController.text.trim(), // Boşlukları temizle
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
        }
      }
    } catch (e) {
      debugPrint('Şifre değiştirme hatası: $e');
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => ProfilePasswordDialog(
        currentPasswordController: _currentPasswordController,
        newPasswordController: _newPasswordController,
        confirmPasswordController: _confirmPasswordController,
        onChangePassword: _changePassword,
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SharedProfileAvatarCard(
                      fullName: '${_firstName ?? ''} ${_lastName ?? ''}'.trim(),
                      subtitle: _jobTitle,
                    ),
                    SizedBox(height: screenWidth * 0.04),
                    SharedProfileInfoCard(
                      fields: [
                        ProfileInfoField(
                          icon: Icons.person_outline,
                          label: 'Kullanıcı Adı',
                          value: _username ?? '',
                        ),
                        ProfileInfoField(
                          icon: Icons.badge_outlined,
                          label: 'Ad Soyad',
                          value: '${_firstName ?? ''} ${_lastName ?? ''}'
                              .trim(),
                        ),
                        ProfileInfoField(
                          icon: Icons.work_outline,
                          label: 'Yapılan İş',
                          value: _jobTitle ?? '',
                        ),
                        ProfileInfoField(
                          icon: Icons.email_outlined,
                          label: 'E-posta',
                          value: _email ?? '',
                        ),
                      ],
                      onEdit: _handleProfileEdit,
                    ),
                    SizedBox(height: screenWidth * 0.04),
                    SharedPasswordCard(
                      onChangePassword: _showChangePasswordDialog,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
