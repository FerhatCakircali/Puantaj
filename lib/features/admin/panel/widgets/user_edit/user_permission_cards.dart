import 'package:flutter/material.dart';
import '../../../../../services/auth_service.dart';

class UserPermissionCards extends StatelessWidget {
  final Map<String, dynamic> user;
  final AuthService authService;
  final bool isAdmin;
  final bool isBlocked;
  final ValueChanged<bool> onAdminChanged;
  final ValueChanged<bool> onBlockedChanged;

  const UserPermissionCards({
    super.key,
    required this.user,
    required this.authService,
    required this.isAdmin,
    required this.isBlocked,
    required this.onAdminChanged,
    required this.onBlockedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(context, 'Yetki ve Durum', Icons.security),
        const SizedBox(height: 16),

        // Admin Yetkisi Card
        FutureBuilder<bool>(
          future: () async {
            final isTargetSystemAdmin = authService.isSystemAdmin(user);
            final isCurrentSystemAdmin = await authService
                .isCurrentUserSystemAdmin();
            // System admin değilse ve mevcut kullanıcı system admin ise değiştirebilir
            return !isTargetSystemAdmin && isCurrentSystemAdmin;
          }(),
          builder: (context, snapshot) {
            final canChangeAdminStatus = snapshot.data ?? false;
            final isTargetSystemAdmin = authService.isSystemAdmin(user);
            return _buildPermissionCard(
              context: context,
              title: 'Admin Yetkisi',
              subtitle: isTargetSystemAdmin
                  ? 'System Administrator yetkisi değiştirilemez'
                  : (canChangeAdminStatus
                        ? 'Kullanıcıya admin yetkisi ver/kaldır'
                        : 'Sadece System Administrator admin yetkisi verebilir'),
              icon: Icons.admin_panel_settings,
              value: isAdmin,
              enabled: canChangeAdminStatus,
              onChanged: canChangeAdminStatus ? onAdminChanged : null,
              activeColor: Colors.orange,
            );
          },
        ),

        const SizedBox(height: 12),

        // Kullanıcı Durumu Card
        FutureBuilder<bool>(
          future: () async {
            final isTargetSystemAdmin = authService.isSystemAdmin(user);
            // System admin asla bloklanamaz
            return !isTargetSystemAdmin;
          }(),
          builder: (context, snapshot) {
            final canChangeBlockStatus = snapshot.data ?? false;
            final isTargetSystemAdmin = authService.isSystemAdmin(user);
            return _buildPermissionCard(
              context: context,
              title: 'Kullanıcı Durumu',
              subtitle: isTargetSystemAdmin
                  ? 'System Administrator durumu değiştirilemez'
                  : (isBlocked
                        ? 'Kullanıcı şu anda bloklu'
                        : 'Kullanıcı şu anda aktif'),
              icon: isBlocked ? Icons.block : Icons.check_circle,
              value: !isBlocked,
              enabled: canChangeBlockStatus,
              onChanged: canChangeBlockStatus
                  ? (value) => onBlockedChanged(!value)
                  : null,
              activeColor: Colors.green,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required bool enabled,
    required ValueChanged<bool>? onChanged,
    required Color activeColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: enabled
              ? (value
                    ? activeColor.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.3))
              : Colors.grey.withValues(alpha: 0.2),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
        color: enabled
            ? (value ? activeColor.withValues(alpha: 0.05) : Colors.transparent)
            : Colors.grey.withValues(alpha: 0.05),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: enabled ? null : Colors.grey,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: enabled
                  ? Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)
                  : Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
            ),
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: enabled
                ? activeColor.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: enabled ? activeColor : Colors.grey,
            size: 24,
          ),
        ),
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: Colors.white,
        activeTrackColor: activeColor,
        inactiveThumbColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade300
            : Colors.white,
        inactiveTrackColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade400,
        trackOutlineColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.transparent;
          }
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return isDark ? Colors.grey.shade600 : Colors.grey.shade500;
        }),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
