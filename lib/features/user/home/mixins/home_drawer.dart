import 'package:flutter/material.dart';
import '../../../../core/app_globals.dart';

/// Ana ekran drawer widget'ı
class HomeDrawer extends StatelessWidget {
  final String firstName;
  final String lastName;
  final bool isAdmin;
  final int? selectedIndex;
  final Function(int) onItemTap;
  final VoidCallback onThemeToggle;
  final VoidCallback onLogout;
  final bool isDarkMode;

  const HomeDrawer({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.isAdmin,
    required this.selectedIndex,
    required this.onItemTap,
    required this.onThemeToggle,
    required this.onLogout,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Column(
        children: <Widget>[
          // Header with avatar and user info
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.business_center,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                // User name
                Text(
                  '$firstName $lastName',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                // Role
                Text(
                  isAdmin ? 'Yönetici' : 'Kullanıcı',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.people_outline,
                  title: 'Çalışanlar',
                  index: 0,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.calendar_today_outlined,
                  title: 'Yevmiye',
                  index: 1,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.payment_outlined,
                  title: 'Ödeme',
                  index: 2,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.assessment_outlined,
                  title: 'Raporlar',
                  index: 3,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.history_outlined,
                  title: 'Ödeme Geçmişi',
                  index: 4,
                ),
                if (isAdmin)
                  _buildDrawerItem(
                    context,
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Admin Panel',
                    index: 5,
                  ),
                _buildDrawerItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'Profil',
                  index: 6,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Hatırlatıcılar',
                  index: 7,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.notifications_active_outlined,
                  title: 'Bildirimler',
                  index: 8,
                ),
              ],
            ),
          ),
          // Theme toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (context, mode, _) {
                final isDark = mode == ThemeMode.dark;
                return ListTile(
                  leading: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    isDark ? 'Açık Tema' : 'Koyu Tema',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (_) => onThemeToggle(),
                    activeColor: Colors.white,
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    inactiveThumbColor: isDark
                        ? Colors.grey.shade300
                        : Colors.white,
                    inactiveTrackColor: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade400,
                    trackOutlineColor: MaterialStateProperty.resolveWith((
                      states,
                    ) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.transparent;
                      }
                      return isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade500;
                    }),
                  ),
                  onTap: onThemeToggle,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                );
              },
            ),
          ),
          // Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Çıkış Yap',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: onLogout,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int index,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      onTap: () => onItemTap(index),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
