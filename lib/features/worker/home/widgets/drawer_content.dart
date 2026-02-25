import 'package:flutter/material.dart';
import 'drawer_item.dart';
import '../../../../core/app_globals.dart';

/// Modern Worker Drawer içerik widget'ı - Minimal tasarım
class WorkerHomeScreenDrawerContent extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTap;
  final VoidCallback onThemeToggle;
  final VoidCallback onLogout;

  const WorkerHomeScreenDrawerContent({
    super.key,
    required this.selectedIndex,
    required this.onItemTap,
    required this.onThemeToggle,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.025,
                vertical: screenHeight * 0.005,
              ),
              children: <Widget>[
                WorkerHomeScreenDrawerItem(
                  icon: Icons.home_outlined,
                  text: 'Anasayfa',
                  index: 0,
                  selectedIndex: selectedIndex,
                  onTap: () => onItemTap(0),
                ),
                WorkerHomeScreenDrawerItem(
                  icon: Icons.history_outlined,
                  text: 'Geçmiş',
                  index: 1,
                  selectedIndex: selectedIndex,
                  onTap: () => onItemTap(1),
                ),
                WorkerHomeScreenDrawerItem(
                  icon: Icons.notifications_outlined,
                  text: 'Bildirimler',
                  index: 2,
                  selectedIndex: selectedIndex,
                  onTap: () => onItemTap(2),
                ),
                WorkerHomeScreenDrawerItem(
                  icon: Icons.notifications_active_outlined,
                  text: 'Hatırlatıcılar',
                  index: 3,
                  selectedIndex: selectedIndex,
                  onTap: () => onItemTap(3),
                ),
                WorkerHomeScreenDrawerItem(
                  icon: Icons.person_outline,
                  text: 'Profil',
                  index: 4,
                  selectedIndex: selectedIndex,
                  onTap: () => onItemTap(4),
                ),
              ],
            ),
          ),
          // Theme toggle
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.025,
              vertical: screenHeight * 0.005,
            ),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (context, mode, _) {
                final isDark = mode == ThemeMode.dark;
                return ListTile(
                  leading: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: screenWidth * 0.07,
                  ),
                  title: Text(
                    isDark ? 'Açık Tema' : 'Koyu Tema',
                    style: TextStyle(
                      fontSize: screenWidth * 0.042,
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.01,
                  ),
                );
              },
            ),
          ),
          // Logout
          Padding(
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.025,
              screenHeight * 0.005,
              screenWidth * 0.025,
              screenHeight * 0.015,
            ),
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: theme.colorScheme.error,
                size: screenWidth * 0.07,
              ),
              title: Text(
                'Çıkış Yap',
                style: TextStyle(
                  fontSize: screenWidth * 0.042,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.error,
                ),
              ),
              onTap: onLogout,
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.01,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
