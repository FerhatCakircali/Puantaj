import 'package:flutter/material.dart';
import '../../../../../../../models/notification_settings.dart';
import '../constants/notification_settings_constants.dart';
import 'custom_switch_tile.dart';
import 'info_box_widget.dart';
import 'time_selector_widget.dart';

/// Hatırlatıcı ayarları kartı
///
/// Bildirim hatırlatıcı ayarlarını yönetmek için kullanılır.
class ReminderSettingsCard extends StatelessWidget {
  final bool isEnabled;
  final String selectedTime;
  final bool isLoading;
  final NotificationSettings? settings;
  final ValueChanged<bool> onToggleChanged;
  final VoidCallback onTimeSelect;
  final VoidCallback onSaveSettings;

  const ReminderSettingsCard({
    super.key,
    required this.isEnabled,
    required this.selectedTime,
    required this.isLoading,
    required this.settings,
    required this.onToggleChanged,
    required this.onTimeSelect,
    required this.onSaveSettings,
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
            const SizedBox(height: NotificationSettingsConstants.largeSpacing),
            const InfoBoxWidget(
              title: 'Nasıl Çalışır?',
              message:
                  'Hatırlatıcı aktif olduğu sürece ve yevmiye girişi yapılmadığında her gün belirlenen saatte bildirim gönderilir.',
            ),
            const SizedBox(height: NotificationSettingsConstants.largeSpacing),
            _buildToggleSwitch(context),
            const SizedBox(height: NotificationSettingsConstants.spacing),
            Divider(color: colorScheme.outlineVariant),
            const SizedBox(height: NotificationSettingsConstants.spacing),
            TimeSelectorWidget(
              selectedTime: selectedTime,
              isEnabled: isEnabled,
              onTap: onTimeSelect,
            ),
            if (settings == null && !isLoading) ...[
              const SizedBox(
                height: NotificationSettingsConstants.sectionSpacing,
              ),
              InfoBoxWidget(
                title: '',
                message:
                    'Bildirim ayarlarınız bulunmuyor. Ayarları kaydetmek için aşağıdaki butona tıklayın.',
                icon: Icons.info_outline,
                backgroundColor: colorScheme.tertiaryContainer.withValues(
                  alpha: NotificationSettingsConstants.infoBoxBackgroundAlpha,
                ),
                borderColor: colorScheme.tertiary.withValues(
                  alpha: NotificationSettingsConstants.infoBoxBorderAlpha,
                ),
                iconColor: colorScheme.tertiary,
              ),
            ],
            const SizedBox(height: NotificationSettingsConstants.largeSpacing),
            _buildSaveButton(context),
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
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(
              NotificationSettingsConstants.iconContainerRadius,
            ),
          ),
          child: Icon(
            Icons.notifications_active,
            color: colorScheme.onSecondaryContainer,
            size: NotificationSettingsConstants.iconSize,
          ),
        ),
        const SizedBox(width: NotificationSettingsConstants.spacing),
        Text(
          'Hatırlatıcı Ayarları',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSwitch(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomSwitchTile(
      title: 'Hatırlatıcıyı Etkinleştir',
      subtitle: isEnabled
          ? 'Günlük bildirimler aktif'
          : 'Günlük bildirimler kapalı',
      value: isEnabled,
      onChanged: onToggleChanged,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEnabled
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isEnabled ? Icons.notifications_active : Icons.notifications_off,
          color: isEnabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: NotificationSettingsConstants.smallIconSize,
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: isLoading ? null : onSaveSettings,
        icon: isLoading
            ? const SizedBox(
                width: NotificationSettingsConstants.progressIndicatorSize,
                height: NotificationSettingsConstants.progressIndicatorSize,
                child: CircularProgressIndicator(
                  strokeWidth: NotificationSettingsConstants
                      .progressIndicatorStrokeWidth,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: Text(
          isLoading ? 'Kaydediliyor...' : 'Hatırlatıcı Ayarlarını Kaydet',
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: NotificationSettingsConstants.buttonVerticalPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              NotificationSettingsConstants.buttonBorderRadius,
            ),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
