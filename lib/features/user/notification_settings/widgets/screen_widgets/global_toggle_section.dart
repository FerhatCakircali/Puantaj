import 'package:flutter/material.dart';
import '../../../../../models/notification_settings.dart';
import 'global_toggle/constants/notification_settings_constants.dart';
import 'global_toggle/helpers/theme_helper.dart';
import 'global_toggle/widgets/auto_approve_card.dart';
import 'global_toggle/widgets/reminder_settings_card.dart';

/// Global bildirim ayarları bölümü
///
/// Hatırlatıcı ve otomatik onay ayarlarını yönetir.
class GlobalToggleSection extends StatelessWidget {
  final bool isEnabled;
  final bool autoApproveTrusted;
  final String selectedTime;
  final bool isLoading;
  final NotificationSettings? settings;
  final bool hasNotificationPermission;
  final ValueChanged<bool> onToggleChanged;
  final ValueChanged<bool> onAutoApproveChanged;
  final VoidCallback onTimeSelect;
  final VoidCallback onSaveSettings;
  final VoidCallback onRequestPermissions;

  const GlobalToggleSection({
    super.key,
    required this.isEnabled,
    required this.autoApproveTrusted,
    required this.selectedTime,
    required this.isLoading,
    required this.settings,
    required this.hasNotificationPermission,
    required this.onToggleChanged,
    required this.onAutoApproveChanged,
    required this.onTimeSelect,
    required this.onSaveSettings,
    required this.onRequestPermissions,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ThemeHelper.isTablet(context);
    final padding = isTablet
        ? NotificationSettingsConstants.tabletPadding
        : NotificationSettingsConstants.mobilePadding;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReminderSettingsCard(
            isEnabled: isEnabled,
            selectedTime: selectedTime,
            isLoading: isLoading,
            settings: settings,
            onToggleChanged: onToggleChanged,
            onTimeSelect: onTimeSelect,
            onSaveSettings: onSaveSettings,
          ),
          const SizedBox(height: NotificationSettingsConstants.sectionSpacing),
          AutoApproveCard(
            autoApproveTrusted: autoApproveTrusted,
            onAutoApproveChanged: onAutoApproveChanged,
          ),
        ],
      ),
    );
  }
}
