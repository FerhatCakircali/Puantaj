import 'package:flutter/material.dart';
import '../constants/notification_settings_constants.dart';

/// Saat seçici widget'ı
///
/// Hatırlatma saati seçmek için kullanılır.
class TimeSelectorWidget extends StatelessWidget {
  final String selectedTime;
  final bool isEnabled;
  final VoidCallback onTap;

  const TimeSelectorWidget({
    super.key,
    required this.selectedTime,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(
        NotificationSettingsConstants.infoBoxRadius,
      ),
      child: Container(
        padding: const EdgeInsets.all(
          NotificationSettingsConstants.infoBoxPadding,
        ),
        decoration: BoxDecoration(
          color: isEnabled
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(
            NotificationSettingsConstants.infoBoxRadius,
          ),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: isEnabled
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: NotificationSettingsConstants.iconSize,
            ),
            const SizedBox(width: NotificationSettingsConstants.sectionSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hatırlatma Saati',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedTime,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isEnabled
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isEnabled
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
