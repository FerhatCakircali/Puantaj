import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/user_data_provider.dart';
import '../core/providers/theme_provider.dart';
import '../services/auth_service.dart';

class AppDrawer extends ConsumerWidget {
  final AuthService _authService = AuthService();

  AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userDataProvider);
    final firstName = currentUser?['first_name'] as String? ?? '';
    final lastName = currentUser?['last_name'] as String? ?? '';

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.75,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      elevation: 16.0,
      child: Column(
        children: <Widget>[
          _buildDrawerHeader(context, firstName, lastName),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                _buildDrawerItem(
                  context,
                  icon: Icons.people_alt_outlined,
                  text: 'Çalışanlar',
                  onTap: () => context.go('/home', extra: {'tab': 0}),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.calendar_month_outlined,
                  text: 'Yevmiye',
                  onTap: () => context.go('/home', extra: {'tab': 1}),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.payment_outlined,
                  text: 'Ödeme',
                  onTap: () => context.go('/home', extra: {'tab': 2}),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.bar_chart_outlined,
                  text: 'Raporlar',
                  onTap: () => context.go('/home', extra: {'tab': 3}),
                ),
                if (currentUser?['is_admin'] == true)
                  _buildDrawerItem(
                    context,
                    icon: Icons.admin_panel_settings_outlined,
                    text: 'Admin Panel',
                    onTap: () => context.go('/home', extra: {'tab': 4}),
                  ),
                _buildDrawerItem(
                  context,
                  icon: Icons.person_outline,
                  text: 'Profil',
                  onTap: () => context.go('/home', extra: {'tab': 5}),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.notifications_outlined,
                  text: 'Bildirim Ayarları',
                  onTap: () => context.go('/notification_settings'),
                ),
                const Divider(
                  height: 32,
                  thickness: 0.5,
                  indent: 20,
                  endIndent: 20,
                  color: Colors.grey,
                ),
                                Builder(
                  builder: (context) {
                    final themeMode = ref.watch(themeStateProvider);
                    final isDark = themeMode == ThemeMode.dark;
                    return _buildDrawerItem(
                      context,
                      icon: isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      text: 'Tema',
                      onTap: () {
                        final newMode = isDark
                            ? ThemeMode.light
                            : ThemeMode.dark;
                        ref.read(themeStateProvider.notifier).setTheme(newMode);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(
            height: 16,
            thickness: 0.5,
            indent: 20,
            endIndent: 20,
            color: Colors.grey,
          ),
          _buildLogoutButton(context),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 8.0),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(
    BuildContext context,
    String firstName,
    String lastName,
  ) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.only(topRight: Radius.circular(30)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/icons/icon.png', width: 60, height: 60),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Puantaj',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Takip',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (firstName.isNotEmpty || lastName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      '$firstName $lastName',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 26,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Material(
        color: Theme.of(
          context,
        ).colorScheme.errorContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(10),
          hoverColor: Theme.of(
            context,
          ).colorScheme.error.withValues(alpha: 0.1),
          splashColor: Theme.of(
            context,
          ).colorScheme.error.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.logout_outlined,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Çıkış Yap',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Oturumu kapatmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _authService.signOut();
                            // Consumer ile ref'e erişim sağlanıyor
              if (context.mounted) {
                final container = ProviderScope.containerOf(context);
                container.read(authStateProvider.notifier).logout();
                context.go('/login');
              }
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}
