import 'package:flutter/material.dart';
import '../constants/notification_settings_constants.dart';

/// Bilgi kutusu widget'ı
///
/// Kullanıcıya bilgilendirme mesajları göstermek için kullanılır.
class InfoBoxWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;

  const InfoBoxWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBackgroundColor =
        backgroundColor ??
        colorScheme.primaryContainer.withValues(
          alpha: NotificationSettingsConstants.infoBoxBackgroundAlpha,
        );
    final effectiveBorderColor =
        borderColor ??
        colorScheme.primary.withValues(
          alpha: NotificationSettingsConstants.infoBoxBorderAlpha,
        );
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(
        NotificationSettingsConstants.infoBoxPadding,
      ),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(
          NotificationSettingsConstants.infoBoxRadius,
        ),
        border: Border.all(color: effectiveBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: effectiveIconColor,
            size: NotificationSettingsConstants.smallIconSize,
          ),
          const SizedBox(width: NotificationSettingsConstants.spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
