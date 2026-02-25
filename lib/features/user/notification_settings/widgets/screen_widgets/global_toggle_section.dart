import 'package:flutter/material.dart';
import '../../../../../models/notification_settings.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final padding = isTablet ? 24.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hatırlatıcı Ayarları Kartı
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_active,
                          color: colorScheme.onSecondaryContainer,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Hatırlatıcı Ayarları',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Nasıl Çalışır Bilgi Kutusu
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nasıl Çalışır?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hatırlatıcı aktif olduğu sürece ve yevmiye girişi yapılmadığında her gün belirlenen saatte bildirim gönderilir.',
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
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hatırlatıcıyı Etkinleştir'),
                    subtitle: Text(
                      isEnabled
                          ? 'Günlük bildirimler aktif'
                          : 'Günlük bildirimler kapalı',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    value: isEnabled,
                    onChanged: onToggleChanged,
                    activeColor: Colors.white,
                    activeTrackColor: colorScheme.primary,
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
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: isEnabled
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: colorScheme.outlineVariant),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: isEnabled ? onTimeSelect : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? colorScheme.surfaceContainerHighest
                            : colorScheme.surfaceContainerHighest.withValues(
                                alpha: 0.5,
                              ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: isEnabled
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
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
                                : colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.5,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (settings == null && !isLoading) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.tertiary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.tertiary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Bildirim ayarlarınız bulunmuyor. Ayarları kaydetmek için aşağıdaki butona tıklayın.',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Kaydet Butonu
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isLoading ? null : onSaveSettings,
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        isLoading
                            ? 'Kaydediliyor...'
                            : 'Hatırlatıcı Ayarlarını Kaydet',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Güvenilir Çalışanlar Otomatik Onay Kartı
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: autoApproveTrusted
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          autoApproveTrusted
                              ? Icons.verified
                              : Icons.shield_outlined,
                          color: autoApproveTrusted
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Otomatik Onay'),
                    subtitle: Text(
                      autoApproveTrusted
                          ? 'Güvenilir çalışanlar için aktif'
                          : 'Tüm girişler manuel onay gerektirir',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    value: autoApproveTrusted,
                    onChanged: onAutoApproveChanged,
                    activeColor: Colors.white,
                    activeTrackColor: colorScheme.primary,
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
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: autoApproveTrusted
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        autoApproveTrusted
                            ? Icons.check_circle
                            : Icons.pending_actions,
                        color: autoApproveTrusted
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
