import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/app_globals.dart';
import '../../../../core/providers/theme_provider.dart';
import '../mixins/login_auth_mixin.dart';
import '../mixins/login_credential_mixin.dart';
import '../../../../features/worker/services/worker_notification_listener_service.dart';
import '../../../../widgets/theme_toggle_animation.dart';
import '../widgets/index.dart';

// ⚡ PHASE 3: ConsumerStatefulWidget'a geçiş
class LoginScreen extends ConsumerStatefulWidget {
  final bool isFromAccountSwitch;

  const LoginScreen({super.key, this.isFromAccountSwitch = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with LoginAuthMixin, LoginCredentialMixin {
  // Admin controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Worker controllers
  final TextEditingController _workerUsernameController =
      TextEditingController();
  final TextEditingController _workerPasswordController =
      TextEditingController();

  // PageView controller
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final GlobalKey _themeIconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _stopWorkerNotificationListener();
    // Initialize'ı async olarak çalıştır ama UI'ı blokla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initialize();
      }
    });
  }

  /// Çalışan bildirim dinleyicisini durdur
  Future<void> _stopWorkerNotificationListener() async {
    try {
      debugPrint(
        '🧹 LoginScreen: Çalışan bildirim dinleyicisi durduruluyor...',
      );
      await WorkerNotificationListenerService.instance.stopListening();
      debugPrint('✅ LoginScreen: Çalışan bildirim dinleyicisi durduruldu');
    } catch (e) {
      debugPrint(
        '⚠️ LoginScreen: Çalışan bildirim dinleyicisi durdurulurken hata: $e',
      );
    }
  }

  Future<void> _initialize() async {
    if (!mounted) return;

    // Paralel olarak çalıştır
    await Future.wait([
      initializeCredentialManager(),
      loadSavedCredentials(
        adminUsernameController: _usernameController,
        adminPasswordController: _passwordController,
        workerUsernameController: _workerUsernameController,
        workerPasswordController: _workerPasswordController,
      ),
    ]);

    // Auto login kontrolü
    if (mounted) {
      await checkAutoLogin();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _workerUsernameController.dispose();
    _workerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminSignIn() async {
    await signIn(
      username: _usernameController.text,
      password: _passwordController.text,
      onSuccess: () async {
        await saveAdminCredentials(
          _usernameController.text,
          _passwordController.text,
        );
      },
      onError: (error) {
        if (mounted) {
          showGlobalSnackbar(error, backgroundColor: Colors.red);
        }
      },
      isFromAccountSwitch: widget.isFromAccountSwitch,
    );
  }

  Future<void> _handleWorkerSignIn() async {
    await workerSignIn(
      username: _workerUsernameController.text,
      password: _workerPasswordController.text,
      onSuccess: () async {
        await saveWorkerCredentials(
          _workerUsernameController.text,
          _workerPasswordController.text,
        );
      },
      onError: (error) {
        if (mounted) {
          showGlobalSnackbar(error, backgroundColor: Colors.red);
        }
      },
    );
  }

  // ⚡ PHASE 3: _saveThemeMode kaldırıldı, Riverpod ThemeProvider kullanılıyor

  void _toggleThemeWithAnimation() async {
    // ⚡ PHASE 3: Riverpod ThemeProvider kullan
    final currentMode = ref.read(themeStateProvider);
    final newMode = currentMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;

    // Calculate icon position
    final RenderBox? renderBox =
        _themeIconKey.currentContext?.findRenderObject() as RenderBox?;
    Offset? iconCenter;
    if (renderBox != null) {
      final iconPosition = renderBox.localToGlobal(Offset.zero);
      final iconSize = renderBox.size;
      iconCenter =
          iconPosition + Offset(iconSize.width / 2, iconSize.height / 2);
    }

    // Apply theme change
    await ref.read(themeStateProvider.notifier).setTheme(newMode);

    // Show animation
    if (mounted) {
      await ThemeToggleAnimation.show(
        context,
        goingToDark: newMode == ThemeMode.dark,
        onAnimationComplete: () {},
        center: iconCenter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final maxWidth = isTablet ? 500.0 : double.infinity;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: widget.isFromAccountSwitch
          ? AppBar(
              title: const Text('Yeni Hesap Ekle'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTabIndicator(theme),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: [
                      AdminLoginPage(
                        maxWidth: maxWidth,
                        isTablet: isTablet,
                        isFromAccountSwitch: widget.isFromAccountSwitch,
                        usernameController: _usernameController,
                        passwordController: _passwordController,
                        rememberMe: rememberMe,
                        isLoading: isLoading,
                        errorMessage: errorMessage,
                        onRememberMeChanged: toggleAdminRememberMe,
                        onSignIn: _handleAdminSignIn,
                      ),
                      WorkerLoginPage(
                        maxWidth: maxWidth,
                        isTablet: isTablet,
                        usernameController: _workerUsernameController,
                        passwordController: _workerPasswordController,
                        rememberMe: workerRememberMe,
                        isLoading: isWorkerLoading,
                        errorMessage: workerErrorMessage,
                        onRememberMeChanged: toggleWorkerRememberMe,
                        onSignIn: _handleWorkerSignIn,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ⚡ PHASE 3: Riverpod ThemeProvider kullan
          Consumer(
            builder: (context, ref, _) {
              final mode = ref.watch(themeStateProvider);
              return ThemeToggleButton(
                currentMode: mode,
                onToggle: _toggleThemeWithAnimation,
                iconKey: _themeIconKey,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PageIndicator(
            index: 0,
            currentPage: _currentPage,
            label: 'Yönetici',
            theme: theme,
            onTap: () => _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
          const SizedBox(width: 32),
          PageIndicator(
            index: 1,
            currentPage: _currentPage,
            label: 'Çalışan',
            theme: theme,
            onTap: () => _pageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }
}
