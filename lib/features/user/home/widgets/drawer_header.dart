import 'package:flutter/material.dart';

/// Modern Drawer başlık widget'ı
/// Minimalist ve temiz tasarım
class HomeScreenDrawerHeader extends StatelessWidget {
  final String firstName;
  final String lastName;
  final bool isAdmin;

  const HomeScreenDrawerHeader({
    super.key,
    required this.firstName,
    required this.lastName,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withValues(alpha: 0.95),
                ]
              : [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  theme.colorScheme.surface,
                ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.person,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          // User name
          Text(
            '$firstName $lastName',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isAdmin
                  ? Colors.orange.withValues(alpha: 0.2)
                  : theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isAdmin ? 'Yönetici' : 'Kullanıcı',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isAdmin
                    ? (isDark ? Colors.orange[300] : Colors.orange[700])
                    : theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
