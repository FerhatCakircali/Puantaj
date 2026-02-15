import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../main.dart'; // authStateNotifier için import eklendi
import 'package:puantaj/core/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:ui';
import 'package:go_router/go_router.dart';

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
  bool _isLoading = true;
  String? _username;
  bool _isChangingPassword = false;
  bool _isEditingProfile = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
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
        _isLoading = false;
      });
    } catch (e) {
      print('Kullanıcı bilgileri yüklenirken hata: $e');

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
        _jobTitleController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen tüm alanları doldurunuz.')),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 8,
          ),
          actionsPadding: const EdgeInsets.only(
            bottom: 16,
            right: 16,
            left: 16,
          ),
          title: Column(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.1),
                radius: 28,
                child: Icon(
                  Icons.lock_outline,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Şifre Değiştir',
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
                TextField(
                  controller: _currentPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Mevcut Şifre',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
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
                      Icons.lock_open,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.7),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showCurrentPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(
                        () => _showCurrentPassword = !_showCurrentPassword,
                      ),
                    ),
                  ),
                  obscureText: !_showCurrentPassword,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
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
                      Icons.lock,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.7),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showNewPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _showNewPassword = !_showNewPassword),
                    ),
                  ),
                  obscureText: !_showNewPassword,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre Tekrar',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
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
                      Icons.lock,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.7),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(
                        () => _showConfirmPassword = !_showConfirmPassword,
                      ),
                    ),
                  ),
                  obscureText: !_showConfirmPassword,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Dialogu kapat
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Başlangıçta mounted kontrolü yap
                if (!mounted) return;

                // Şifre değiştirme doğrulama ve işlemi burada
                if (_currentPasswordController.text.trim().isEmpty ||
                    _newPasswordController.text.trim().isEmpty ||
                    _confirmPasswordController.text.trim().isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Lütfen tüm şifre alanlarını doldurunuz.',
                        ),
                      ),
                    );
                  }
                  return; // Boş alan varsa işlemi durdur
                }
                if (_newPasswordController.text.trim() !=
                    _confirmPasswordController.text.trim()) {
                  // Şifreleri trimleyerek karşılaştır
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Yeni şifreler eşleşmiyor.'),
                      ),
                    );
                  }
                  return; // Şifreler eşleşmiyorsa işlemi durdur
                }

                // Doğrulama başarılı, şifre değiştirme işlemini başlat
                await _changePassword(); // changePassword içinde zaten loading ve hata yönetimi var

                if (!mounted) return; // İşlem sonrası dialog kapanabilir

                // İşlem başarılıysa dialogu kapat
                if (!_isChangingPassword) {
                  // Eğer loading state false ise işlem bitmiş demektir
                  Navigator.pop(context);
                }
              },
              child: _isChangingPassword
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Text('Değiştir'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hayır'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Çıkış yapmadan önce mevcut context'i saklayalım
              final BuildContext localContext = context;

              // Çıkış yap (hesapları kaydet ve kayıtlı hesap olup olmadığını kontrol et)
              final hasSavedAccounts = await _authService.signOut();

              // Widget hala mount edilmiş mi kontrol et
              if (!mounted) return;

              // Oturum durumunu güncelle
              authStateNotifier.value = false;

              print(
                'Çıkış yapıldı, kaydedilmiş hesap var mı: $hasSavedAccounts',
              );

              // Kayıtlı hesap varsa ilk hesaba otomatik giriş yap
              if (hasSavedAccounts) {
                print('Kaydedilmiş hesap bulundu, otomatik giriş yapılıyor...');
                final success = await _authService
                    .autoLoginWithFirstSavedAccount();

                if (!mounted) return;

                print('Otomatik giriş sonucu: $success');

                if (success) {
                  // Otomatik giriş başarılı, yeni bir yönlendirme yapılacak
                  // Kullanıcı verilerini güncelle
                  final userData = await _authService.currentUser;
                  // Admin kontrolü yap
                  final isAdmin = await _authService.isAdmin();

                  if (!mounted) return;

                  try {
                    // Admin hesabına veya normal kullanıcı hesabına yönlendir
                    if (isAdmin) {
                      print(
                        'Admin hesabına giriş yapıldı, admin paneline yönlendiriliyor',
                      );
                      GoRouter.of(localContext).go('/admin_accounts');
                    } else {
                      print(
                        'Normal kullanıcı hesabına giriş yapıldı, ana sayfaya yönlendiriliyor',
                      );
                      GoRouter.of(localContext).go('/home');
                    }

                    // Başarılı mesajı göster
                    ScaffoldMessenger.of(localContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${userData?['first_name']} ${userData?['last_name']} hesabına geçiş yapıldı',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    print('Yönlendirme hatası: $e');
                    // Hata durumunda global router'ı kullan
                    GoRouter.of(Navigator.of(context).context).go('/login');
                  }
                  return;
                } else {
                  print(
                    'Otomatik giriş başarısız oldu, login ekranına yönlendiriliyor',
                  );
                }
              } else {
                print(
                  'Kaydedilmiş hesap bulunamadı, login ekranına yönlendiriliyor',
                );
              }

              // Kayıtlı hesap yoksa veya otomatik giriş başarısız olduysa login ekranına yönlendir
              if (!mounted) return;

              try {
                GoRouter.of(localContext).go('/login');
              } catch (e) {
                print('Login yönlendirme hatası: $e');
                // Alternatif yönlendirme
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Evet'),
          ),
        ],
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
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final padding = isTablet ? 32.0 : 16.0;
    final fontSize = isTablet ? 22.0 : 16.0;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar ve isim/ünvan başlığı
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      margin: const EdgeInsets.only(bottom: 24),
                      color: Theme.of(context).cardColor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                size: 56,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${_firstNameController.text} ${_lastNameController.text}',
                              style: TextStyle(
                                fontSize: fontSize + 4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_jobTitleController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _jobTitleController.text,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Kullanıcı Bilgileri Kartı
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Kullanıcı Bilgileri',
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isEditingProfile ? Icons.save : Icons.edit,
                                    color: _isEditingProfile
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                  ),
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          if (!_isEditingProfile) {
                                            setState(
                                              () => _isEditingProfile = true,
                                            );
                                          } else {
                                            _updateProfile();
                                          }
                                        },
                                  tooltip: _isEditingProfile
                                      ? 'Kaydet'
                                      : 'Düzenle',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _username ?? '',
                                    style: TextStyle(
                                      fontSize: fontSize * 0.95,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Kullanıcı Adı',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.7),
                                ),
                                errorText: _usernameError,
                              ),
                              enabled: _isEditingProfile,
                              maxLength: 30,
                              maxLengthEnforcement:
                                  MaxLengthEnforcement.enforced,
                              onChanged: _validateUsername,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'Ad',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.7),
                                ),
                              ),
                              enabled: _isEditingProfile,
                              maxLength: 30,
                              maxLengthEnforcement:
                                  MaxLengthEnforcement.enforced,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Soyad',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.7),
                                ),
                              ),
                              enabled: _isEditingProfile,
                              maxLength: 30,
                              maxLengthEnforcement:
                                  MaxLengthEnforcement.enforced,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _jobTitleController,
                              decoration: InputDecoration(
                                labelText: 'Yapılan İş',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.work_outline,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.7),
                                ),
                              ),
                              enabled: _isEditingProfile,
                              maxLength: 30,
                              maxLengthEnforcement:
                                  MaxLengthEnforcement.enforced,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Şifre İşlemleri Kartı
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Şifre İşlemleri',
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isChangingPassword
                                    ? null
                                    : _showChangePasswordDialog,
                                icon: const Icon(Icons.lock),
                                label: const Text('Şifre Değiştir'),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.dark:
        await prefs.setString('theme_mode', 'dark');
        break;
      case ThemeMode.light:
        await prefs.setString('theme_mode', 'light');
        break;
      case ThemeMode.system:
        await prefs.setString('theme_mode', 'system');
        break;
    }
  }
}

class ThemeChangeEffect extends StatefulWidget {
  final bool goingToDark;
  const ThemeChangeEffect({Key? key, required this.goingToDark})
    : super(key: key);

  @override
  State<ThemeChangeEffect> createState() => _ThemeChangeEffectState();
}

class _ThemeChangeEffectState extends State<ThemeChangeEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnim = Tween<double>(
      begin: 0.1,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacityAnim = Tween<double>(
      begin: 0.85,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final appBarHeight = kToolbarHeight;
    final statusBar = MediaQuery.of(context).padding.top;
    final center = Offset(size.width / 2, statusBar + appBarHeight / 2);
    // Gradient renkler
    final gradient = widget.goingToDark
        ? LinearGradient(
            colors: [
              const Color(0xFF23272B).withOpacity(0.95),
              const Color(0xFF4F8EF7).withOpacity(0.7),
              const Color(0xFF181C20).withOpacity(0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              const Color(0xFF4F8EF7).withOpacity(0.95),
              const Color(0xFF00BFAE).withOpacity(0.7),
              const Color(0xFFF7F9FB).withOpacity(0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    return Stack(
      children: [
        Positioned(
          left: center.dx - (size.width * 1.2) / 2,
          top: center.dy - (size.width * 1.2) / 2,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnim.value,
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        width: size.width * 1.2,
                        height: size.width * 1.2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: gradient,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Parıltı efekti
        Positioned(
          left: center.dx - 40,
          top: center.dy - 40,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _glowAnim.value * 0.7,
                child: Transform.scale(
                  scale: 0.7 + _glowAnim.value * 1.2,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.7),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.7),
                          blurRadius: 32,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
