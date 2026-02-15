// login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'admin_panel_screen.dart';
import '../main.dart';
import '../widgets/password_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../widgets/theme_toggle_animation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:credential_manager/credential_manager.dart';

class LoginScreen extends StatefulWidget {
  final bool isFromAccountSwitch;

  const LoginScreen({super.key, this.isFromAccountSwitch = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = false;

  final GlobalKey _themeIconKey = GlobalKey();

  AuthService _authService = AuthService();

  // Web platformunda credential manager desteklenmiyor
  CredentialManager? _credentialManager;

  static const String _rememberMeKey = 'remember_me';
  static const String _savedUsernameKey = 'saved_username';
  static const String _savedPasswordKey = 'saved_password';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _initializeCredentialManager();
  }

  void _initializeCredentialManager() async {
    // Web platformunda credential manager desteklenmiyor
    if (kIsWeb) {
      return;
    }

    _credentialManager = CredentialManager();
    if (_credentialManager?.isSupportedPlatform == true) {
      await _credentialManager!.init(
        preferImmediatelyAvailableCredentials: true,
      );
    }
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    setState(() {
      _rememberMe = rememberMe;
    });
    if (rememberMe) {
      final savedUsername = prefs.getString(_savedUsernameKey) ?? '';
      final savedPassword = prefs.getString(_savedPasswordKey) ?? '';
      _usernameController.text = savedUsername;
      _passwordController.text = savedPassword;
    }
  }

  Future<void> _saveCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString(_savedUsernameKey, username);
      await prefs.setString(_savedPasswordKey, password);
    } else {
      await prefs.remove(_savedUsernameKey);
      await prefs.remove(_savedPasswordKey);
    }
    await prefs.setBool(_rememberMeKey, _rememberMe);
  }

  Future<void> _signIn() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      if (mounted) {
        showGlobalSnackbar(
          'Lütfen tüm alanları doldurunuz',
          backgroundColor: Colors.red,
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Context'i başlamadan önce kaydedelim
      final localContext = context;

      final error = await _authService.signIn(
        _usernameController.text,
        _passwordController.text,
      );

      if (error != null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = error;
          _isLoading = false;
        });
      } else {
        // Oturum durumunu güncelle
        authStateNotifier.value = true;

        // Kimlik bilgilerini kaydet (eğer "Beni Hatırla" seçili ise)
        await _saveCredentials(
          _usernameController.text,
          _passwordController.text,
        );

        // Başarılı girişten sonra Google Şifre Yöneticisi'ne kaydetme isteği gönder
        try {
          if (!kIsWeb && _credentialManager?.isSupportedPlatform == true) {
            final passwordCredential = PasswordCredential(
              username: _usernameController.text,
              password: _passwordController.text,
            );
            await _credentialManager!.savePasswordCredentials(
              passwordCredential,
            );
          }
        } catch (e) {
          print(
            'CredentialManager ile şifre kaydetme isteği gönderilirken hata: $e',
          );
        }

        // Yükleme durumunu kapat
        if (mounted) {
          setState(() => _isLoading = false);
        }

        // GoRouter ile uygun sayfaya yönlendir
        try {
          if (mounted && localContext != null) {
            if (widget.isFromAccountSwitch) {
              // Hesap değiştirme modunda, kullanıcı başarıyla giriş yaptı

              // 1. Yeni giriş yapılan kullanıcının bilgilerini al
              final userData = await _authService.currentUser;
              if (userData == null) {
                throw Exception('Kullanıcı bilgileri alınamadı');
              }

              // 2. Yeni kullanıcıyı kaydedilmiş hesaplara ekle
              await _authService.saveCurrentUserToSavedAccounts();

              // 3. Login ekranını kapat ve ana ekrana dön
              Navigator.of(context).pop();

              // 4. Başarılı mesajı göster (kısa bir gecikme ile)
              Future.delayed(Duration(milliseconds: 300), () {
                try {
                  final username = userData['username'] as String? ?? '';
                  final firstName = userData['first_name'] as String? ?? '';
                  final lastName = userData['last_name'] as String? ?? '';
                  showGlobalSnackbar(
                    '$firstName $lastName ($username) hesabı başarıyla eklendi',
                    backgroundColor: Colors.green,
                  );
                } catch (e) {
                  print('SnackBar gösterilirken hata: $e');
                }
              });
            } else {
              // Normal giriş - ana ekrana dön
              GoRouter.of(localContext).go('/home');
            }
          }
        } catch (e) {
          print('Yönlendirme hatası: $e');
        }
      }
    } catch (e) {
      print('Giriş hatası: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Giriş yapılırken bir hata oluştu: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
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

  void _toggleThemeWithAnimation() async {
    final currentMode = themeModeNotifier.value;
    final newMode = currentMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;

    // Animasyon tamamlandığında yapılacak işlemler (gerekirse eklenebilir)
    void onAnimationComplete() {
      // Burada ek işlemler yapılabilir
    }

    // İkon pozisyonunu hesapla
    final RenderBox? renderBox =
        _themeIconKey.currentContext?.findRenderObject() as RenderBox?;
    Offset? iconCenter;
    if (renderBox != null) {
      final iconPosition = renderBox.localToGlobal(Offset.zero);
      final iconSize = renderBox.size;
      iconCenter =
          iconPosition + Offset(iconSize.width / 2, iconSize.height / 2);
    }

    // Önce tema değişimini uygula
    themeModeNotifier.value = newMode;
    _saveThemeMode(newMode);

    // Sonra animasyonu göster
    await ThemeToggleAnimation.show(
      context,
      goingToDark: newMode == ThemeMode.dark,
      onAnimationComplete: onAnimationComplete,
      center: iconCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final maxWidth = isTablet ? 500.0 : double.infinity;

    return Scaffold(
      appBar: widget.isFromAccountSwitch
          ? AppBar(
              title: const Text('Yeni Hesap Ekle'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            )
          : null,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32 : 16,
                      vertical: isTablet ? 32 : 16,
                    ),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(
                              widget.isFromAccountSwitch
                                  ? Icons.account_circle_outlined
                                  : Icons.lock_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              widget.isFromAccountSwitch
                                  ? 'Yeni Hesap Ekle'
                                  : 'Giriş Yap',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            if (widget.isFromAccountSwitch)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Giriş yaparak yeni bir hesap ekleyebilirsiniz.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            AutofillGroup(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _usernameController,
                                    decoration: InputDecoration(
                                      labelText: 'Kullanıcı Adı',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          width: 2,
                                        ),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                      ),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [
                                      AutofillHints.username,
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  PasswordField(
                                    controller: _passwordController,
                                    labelText: 'Şifre',
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (newValue) {
                                    setState(() {
                                      _rememberMe = newValue ?? false;
                                    });
                                  },
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _rememberMe = !_rememberMe;
                                    });
                                  },
                                  child: const Text('Beni Hatırla'),
                                ),
                              ],
                            ),
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text.rich(
                                  TextSpan(
                                    text: '$_errorMessage ',
                                    style: const TextStyle(color: Colors.red),
                                    children: <TextSpan>[
                                      if (_errorMessage ==
                                          'Hesabınız yönetici tarafından onaylanana kadar giriş yapamazsınız.')
                                        TextSpan(
                                          text:
                                              'Lütfen yönetici ile iletişime geçin: ferhatcakircali@gmail.com',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              launchUrl(
                                                Uri(
                                                  scheme: 'mailto',
                                                  path:
                                                      'ferhatcakircali@gmail.com',
                                                ),
                                              );
                                            },
                                        ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signIn,
                                style: ElevatedButton.styleFrom(
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.login),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        'Giriş Yap',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: const Text('Hesabınız yok mu? Kayıt Ol'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 32,
            right: 16,
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (context, mode, _) {
                final isDark = mode == ThemeMode.dark;
                return Padding(
                  padding: const EdgeInsets.only(right: 0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: child.key == const ValueKey('dark')
                          ? Tween<double>(begin: 1, end: 0.75).animate(anim)
                          : Tween<double>(begin: 0.75, end: 1).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: IconButton(
                      key: _themeIconKey,
                      tooltip: isDark ? 'Açık moda geç' : 'Koyu moda geç',
                      icon: Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: _toggleThemeWithAnimation,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
