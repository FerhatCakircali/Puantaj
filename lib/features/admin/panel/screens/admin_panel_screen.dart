import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../../../../core/app_globals.dart';
import '../../../../widgets/theme_toggle_animation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/index.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final GlobalKey _themeIconKey = GlobalKey();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

    void onAnimationComplete() {}

    final RenderBox? renderBox =
        _themeIconKey.currentContext?.findRenderObject() as RenderBox?;
    Offset? iconCenter;
    if (renderBox != null) {
      final iconPosition = renderBox.localToGlobal(Offset.zero);
      final iconSize = renderBox.size;
      iconCenter =
          iconPosition + Offset(iconSize.width / 2, iconSize.height / 2);
    }

    themeModeNotifier.value = newMode;
    _saveThemeMode(newMode);

    await ThemeToggleAnimation.show(
      context,
      goingToDark: newMode == ThemeMode.dark,
      onAnimationComplete: onAnimationComplete,
      center: iconCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: ValueListenableBuilder<ThemeMode>(
          valueListenable: themeModeNotifier,
          builder: (context, mode, _) {
            final isDark = mode == ThemeMode.dark;
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
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
        title: const Text('Admin Paneli'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.people), text: 'Kullanıcılar'),
            Tab(icon: Icon(Icons.person), text: 'Profil'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const DashboardTab(),
          const UsersTab(),
          ProfileTab(
            authService: _authService,
            onChangePassword: _showChangePasswordDialog,
            onEditProfile: _showEditProfileDialog,
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => ProfileEditDialog(
        user: user,
        authService: _authService,
        onSuccess: () => setState(() {}),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => PasswordChangeDialog(authService: _authService),
    );
  }

  void _showLogoutDialog() {
    // Logout öncesi Dashboard tab'ına geç (eski sayfaları gizle)
    _tabController.animateTo(0);

    // Kısa bir gecikme ile logout dialog'unu göster
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        showAdminLogoutDialog(context: context, authService: _authService);
      }
    });
  }
}
