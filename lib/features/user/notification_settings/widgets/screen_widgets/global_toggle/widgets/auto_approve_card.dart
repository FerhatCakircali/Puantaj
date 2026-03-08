import 'package:flutter/material.dart';
import '../constants/notification_settings_constants.dart';
import 'custom_switch_tile.dart';

/// Otomatik onay kartı
///
/// Güvenilir çalışanlar için otomatik onay ayarlarını yönetir.
class AutoApproveCard extends StatelessWidget {
  final bool autoApproveTrusted;
  final ValueChanged<bool> onAutoApproveChanged;

  const AutoApproveCard({
    super.key,
    required this.autoApproveTrusted,
    required this.onAutoApproveChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          NotificationSettingsConstants.cardBorderRadius,
        ),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: NotificationSettingsConstants.cardBorderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          NotificationSettingsConstants.cardPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(
              height: NotificationSettingsConstants.sectionSpacing,
            ),
            _buildToggleSwitch(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(
            NotificationSettingsConstants.iconContainerSize,
          ),
          decoration: BoxDecoration(
            color: autoApproveTrusted
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(
              NotificationSettingsConstants.iconContainerRadius,
            ),
          ),
          child: Icon(
            autoApproveTrusted ? Icons.verified : Icons.shield_outlined,
            color: autoApproveTrusted
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
            size: NotificationSettingsConstants.iconSize,
          ),
        ),
        const SizedBox(width: NotificationSettingsConstants.spacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Güvenilir Çalışanları Otomatik Onayla',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Güvenilir olarak işaretlenen çalışanların yevmiye girişleri otomatik onaylanır',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSwitch(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomSwitchTile(
      title: 'Otomatik Onay',
      subtitle: autoApproveTrusted
          ? 'Güvenilir çalışanlar için aktif'
          : 'Tüm girişler manuel onay gerektirir',
      value: autoApproveTrusted,
      onChanged: onAutoApproveChanged,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: autoApproveTrusted
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          autoApproveTrusted ? Icons.check_circle : Icons.pending_actions,
          color: autoApproveTrusted
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
          size: NotificationSettingsConstants.smallIconSize,
        ),
      ),
    );
  }
}
