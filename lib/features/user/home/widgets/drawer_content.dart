import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'drawer_item.dart';
import '../../../../core/providers/theme_provider.dart';

/// Modern Drawer içerik widget'ı
/// Kullanıcılar panelindeki tasarıma uygun
class HomeScreenDrawerContent extends ConsumerWidget {
  final int? selectedIndex;
  final bool isAdmin;
  final Function(int) onItemTap;
  final VoidCallback onThemeToggle;
  final VoidCallback onLogout;

  const HomeScreenDrawerContent({
    super.key,
    required this.selectedIndex,
    required this.isAdmin,
    required this.onItemTap,
    required this.onThemeToggle,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: <Widget>[
                HomeScreenDrawerItem(
                  icon: Icons.people_outline,
                  text: 'Çalışanlar',
                  index: 0,
                  selectedIndex: selectedIndex,
                  onTap: () => onItemTap(0),
                ),
                HomeScreenDrawerItem(
                  icon: Icons.calendar_today_outlined,
                  text: 'Yevmiye',
                  index: 1,
                  selectedIndex: selectedIndex,
                  onTap: () => onItemTap(1),
                ),
                HomeScreenDrawerItem(
                  icon: Icons.payment_outlined,
                  text: 'Ödeme',
                  index: 2,
                  selectedIndex: selectedIndex,
                  onTap: () => onItemTap(2),
                ),
                HomeScreenDrawerItem(
                  icon: Icons.assessment_outlined,
                  text: 'Raporlar',
                  index: 3,
                  selectedIndex: selectedIndex,
                  onTap: () => onItemTap(3),
                ),
                HomeScreenDrawerItem(
                  icon: Icons.history_outlined,
                  text: 'Ödeme Geçmişi',
                  index: 4,
                  selectedIndex: selectedIndex,
                  onTap: () => onItemTap(4),
                ),
                if (isAdmin)
                  HomeScreenDrawerItem(
                    icon: Icons.admin_panel_settings_outlined,
                    text: 'Admin Panel',
                    index: 5,
                    selectedIndex: selectedIndex,
                    onTap: () => onItemTap(5),
                  ),
                HomeScreenDrawerItem(
                  icon: Icons.person_outline,
                  text: 'Profil',
                  index: 6,
                  selectedIndex: selectedIndex,
                  onTap: () => onItemTap(6),
                ),
                HomeScreenDrawerItem(
                  icon: Icons.notifications_outlined,
                  text: 'Hatırlatıcılar',
                  index: 7,
                  selectedIndex: selectedIndex,
                  onTap: () => onItemTap(7),
                ),
                HomeScreenDrawerItem(
                  icon: Icons.notifications_active_outlined,
                  text: 'Bildirimler',
                  index: 8,
                  selectedIndex: selectedIndex,
                  onTap: () => onItemTap(8),
                ),
              ],
            ),
          ),
          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          // Theme toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Builder(
              builder: (context) {
                final themeMode = ref.watch(themeStateProvider);
                final isDark = themeMode == ThemeMode.dark;
                return ListTile(
                  leading: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  title: Text(
                    'Tema',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (_) => onThemeToggle(),
                    activeColor: Colors.white,
                    activeTrackColor: theme.colorScheme.primary,
                    inactiveThumbColor: isDark
                        ? Colors.grey.shade300
                        : Colors.white,
                    inactiveTrackColor: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade400,
                    trackOutlineColor: WidgetStateProperty.resolveWith((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.transparent;
                      }
                      return isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade500;
                    }),
                  ),
                  onTap: onThemeToggle,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              },
            ),
          ),
          // Logout
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text(
                'Çıkış Yap',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.error,
                ),
              ),
              onTap: onLogout,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
