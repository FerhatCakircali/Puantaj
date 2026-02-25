import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../../profile/widgets/screen_widgets/index.dart';

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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = true;
  String? _username;
  bool _isChangingPassword = false;
  bool _isEditingProfile = false;
  String? _usernameError;

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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _jobTitleController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.currentUser;

      // İşlem bittikten sonra da widget'ın hala ağaçta olup olmadığını kontrol et
      if (!mounted) return;

      setState(() {
        _username = user?['username'] as String?;
        _usernameController.text = user?['username'] as String? ?? '';
        _firstNameController.text = user?['first_name'] as String? ?? '';
        _lastNameController.text = user?['last_name'] as String? ?? '';
        _jobTitleController.text = user?['job_title'] as String? ?? '';
        _emailController.text = user?['email'] as String? ?? '';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Kullanıcı bilgileri yüklenirken hata: $e');

      // Hata durumunda da widget'ın hala ağaçta olup olmadığını kontrol et
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!mounted) return;

    // Alan doğrulama
    if (_usernameController.text.trim().isEmpty ||
        _firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _jobTitleController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen tüm alanları doldurunuz.')),
        );
      }
      return;
    }

    // Email validasyonu
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçerli bir email adresi girin.')),
        );
      }
      return;
    }

    setState(() => _isEditingProfile = true);

    try {
      final trimmedUsername = _usernameController.text.trim();
      final trimmedFirstName = _firstNameController.text.trim();
      final trimmedLastName = _lastNameController.text.trim();
      final trimmedJobTitle = _jobTitleController.text.trim();
      final trimmedEmail = _emailController.text.trim();

      // Kullanıcı adı gerçekten değiştiyse güncelle
      if (trimmedUsername.toLowerCase() != _username?.toLowerCase()) {
        // Önce kullanıcı adını güncelle
        final usernameError = await _authService.updateUsername(
          trimmedUsername,
        );

        if (!mounted) return;

        if (usernameError != null) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(usernameError)));
          }
          // Kullanıcı adı güncellenirken hata oluşursa, diğer bilgileri güncelleme
          setState(() => _isEditingProfile = false);
          return;
        }
      }

      // Sonra diğer bilgileri güncelle
      final error = await _authService.updateProfile(
        trimmedFirstName,
        trimmedLastName,
        trimmedJobTitle,
        email: trimmedEmail,
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
          _usernameController.text = trimmedUsername;
          _firstNameController.text = trimmedFirstName;
          _lastNameController.text = trimmedLastName;
          _jobTitleController.text = trimmedJobTitle;
          setState(() {
            _username = trimmedUsername;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil başarıyla güncellendi.')),
          );
          setState(() => _isEditingProfile = false);
        }
      }
    } finally {
      if (mounted) {
        // İşlem sonunda _isEditingProfile durumunu false yap (hata olsa da olmasa da)
        setState(() => _isEditingProfile = false);
      }
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

    setState(() => _isChangingPassword = true);

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
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
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

  void _validateUsername(String value) async {
    if (!mounted) return;

    if (value.isEmpty) {
      setState(() => _usernameError = 'Kullanıcı adı gerekli');
      return;
    }

    final validUsernameRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!validUsernameRegex.hasMatch(value)) {
      setState(
        () => _usernameError =
            'Sadece İngilizce harfler (A-Z) ve sayılar (0-9) kullanılabilir',
      );
      return;
    }

    // Kullanıcı adı kullanılabilirlik kontrolü
    // Eğer kullanıcı adı değişmediyse kontrol etme
    if (value.toLowerCase() == _username?.toLowerCase()) {
      setState(() => _usernameError = null);
      return;
    }

    final availabilityError = await _authService.checkUsernameAvailability(
      value,
    );

    if (!mounted) return;

    if (availabilityError != null) {
      setState(() => _usernameError = availabilityError);
      return;
    }

    setState(() => _usernameError = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.05,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ProfileAvatarCard(
                      firstName: _firstNameController.text,
                      lastName: _lastNameController.text,
                      jobTitle: _jobTitleController.text,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.width * 0.04),
                    ProfileInfoCard(
                      username: _username,
                      usernameController: _usernameController,
                      firstNameController: _firstNameController,
                      lastNameController: _lastNameController,
                      jobTitleController: _jobTitleController,
                      emailController: _emailController,
                      usernameError: _usernameError,
                      isEditingProfile: _isEditingProfile,
                      isLoading: _isLoading,
                      onEditToggle: () =>
                          setState(() => _isEditingProfile = true),
                      onSave: _updateProfile,
                      onUsernameChanged: _validateUsername,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.width * 0.04),
                    ProfilePasswordCard(
                      isChangingPassword: _isChangingPassword,
                      onChangePasswordPressed: _showChangePasswordDialog,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
