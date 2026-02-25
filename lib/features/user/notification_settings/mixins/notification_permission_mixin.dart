import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_state_mixin.dart';
import 'notification_data_mixin.dart';
import 'helpers/permission_handler.dart';
import 'helpers/settings_saver.dart';

/// Notification Settings ekranı için permission handling mixin'i - Modüler tasarım
///
/// Bu mixin, bildirim izinlerini yönetir.
mixin NotificationPermissionMixin<T extends StatefulWidget>
    on NotificationStateMixin<T>, NotificationDataMixin<T> {
  late final NotificationSettingsSaver _settingsSaver;

  @override
  void initState() {
    super.initState();
    _settingsSaver = NotificationSettingsSaver(notificationService);
  }

  /// Check notification permission
  Future<void> checkNotificationPermission() async {
    final hasPermission = await NotificationPermissionHandler.checkPermission();
    if (!mounted) return;

    setState(() {
      hasNotificationPermission = hasPermission;
    });
  }

  /// Request notification permissions
  Future<void> requestPermissions() async {
    final hasPermission =
        await NotificationPermissionHandler.requestPermission();
    if (!mounted) return;

    setState(() {
      hasNotificationPermission = hasPermission;
    });
  }

  /// Check saved tab index
  Future<void> checkSavedTabIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTabIndex = prefs.getInt('notification_settings_tab_index');

      if (savedTabIndex != null) {
        setState(() {
          tabController.animateTo(savedTabIndex);
        });

        await prefs.remove('notification_settings_tab_index');
      }
    } catch (e) {
      // Hata sessizce yoksayılır
    }
  }

  /// Handle toggle changed
  void handleToggleChanged(bool value) async {
    debugPrint('🔄 Toggle değiştirildi: $value');
    debugPrint('📱 Mevcut izin durumu: $hasNotificationPermission');

    if (value) {
      debugPrint('✅ Etkinleştirme isteği - izin kontrol ediliyor...');
      await requestPermissions();
      debugPrint('📱 İzin kontrolü sonrası: $hasNotificationPermission');

      if (!hasNotificationPermission) {
        if (!mounted) return;
        debugPrint('❌ İzin verilmedi, toggle açılamıyor');
        showSnackBar('Bildirim izni verilmediği için hatırlatıcı açılamadı.');
        return;
      }
    }

    if (!mounted) return;
    debugPrint('💾 State güncelleniyor: $isEnabled -> $value');
    setState(() {
      isEnabled = value;
    });
  }

  /// Handle auto approve changed
  void handleAutoApproveChanged(bool value) async {
    final confirmed = await _showAutoApproveConfirmation(value);

    if (confirmed != true || !mounted) return;

    final oldValue = autoApproveTrusted;
    autoApproveTrusted = value;

    final success = await saveAutoApproveSettings();

    if (!success && mounted) {
      autoApproveTrusted = oldValue;
      setState(() {});
    }
  }

  /// Save auto approve settings
  Future<bool> saveAutoApproveSettings() async {
    try {
      final success = await _settingsSaver.saveAutoApproveSettings(
        currentSettings: settings,
        selectedTime: TimeOfDay(
          hour: int.parse(selectedTime.split(':')[0]),
          minute: int.parse(selectedTime.split(':')[1]),
        ),
        isEnabled: isEnabled,
        autoApproveTrusted: autoApproveTrusted,
        attendanceRequestsEnabled: attendanceRequestsEnabled,
      );

      if (success) {
        showSnackBar(
          autoApproveTrusted
              ? 'Otomatik onay etkinleştirildi'
              : 'Otomatik onay kapatıldı',
        );
        await loadSettings();
        return true;
      } else {
        showSnackBar('Ayarlar kaydedilirken bir hata oluştu');
        return false;
      }
    } catch (e) {
      showSnackBar('Bir hata oluştu: $e');
      return false;
    }
  }

  /// Handle attendance requests changed
  void handleAttendanceRequestsChanged(bool value) async {
    debugPrint('🔄 Yevmiye talep bildirimleri toggle değiştirildi: $value');

    if (value) {
      debugPrint('✅ Etkinleştirme isteği - izin kontrol ediliyor...');
      await requestPermissions();
      debugPrint('📱 İzin kontrolü sonrası: $hasNotificationPermission');

      if (!hasNotificationPermission) {
        if (!mounted) return;
        debugPrint('❌ İzin verilmedi, toggle açılamıyor');
        showSnackBar(
          'Bildirim izni verilmediği için yevmiye talep bildirimleri açılamadı.',
        );
        return;
      }
    }

    if (!mounted) return;
    debugPrint('💾 State güncelleniyor: $attendanceRequestsEnabled -> $value');
    setState(() {
      attendanceRequestsEnabled = value;
    });

    await saveAttendanceRequestsSettings();
  }

  /// Save attendance requests settings
  Future<void> saveAttendanceRequestsSettings() async {
    setState(() => isLoading = true);

    try {
      final success = await _settingsSaver.saveAttendanceRequestsSettings(
        currentSettings: settings,
        selectedTime: TimeOfDay(
          hour: int.parse(selectedTime.split(':')[0]),
          minute: int.parse(selectedTime.split(':')[1]),
        ),
        isEnabled: isEnabled,
        autoApproveTrusted: autoApproveTrusted,
        attendanceRequestsEnabled: attendanceRequestsEnabled,
      );

      if (success) {
        showSnackBar(
          attendanceRequestsEnabled
              ? 'Yevmiye talep bildirimleri etkinleştirildi (FCM ile anında)'
              : 'Yevmiye talep bildirimleri kapatıldı',
        );
        await loadSettings();
      } else {
        showSnackBar('Ayarlar kaydedilirken bir hata oluştu');
      }
    } catch (e) {
      showSnackBar('Bir hata oluştu: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// Build info row widget
  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }

  /// Select time
  Future<void> selectTime() async {
    final TimeOfDay currentTime = TimeOfDay(
      hour: int.parse(selectedTime.split(':')[0]),
      minute: int.parse(selectedTime.split(':')[1]),
    );

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              hourMinuteTextColor: Theme.of(context).colorScheme.onSurface,
              dayPeriodTextColor: Theme.of(context).colorScheme.onSurface,
              dialHandColor: Theme.of(context).colorScheme.primary,
              dialBackgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              dialTextColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;

    if (pickedTime != null) {
      setState(() {
        selectedTime =
            '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<bool?> _showAutoApproveConfirmation(bool value) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          value ? 'Otomatik Onayı Etkinleştir' : 'Otomatik Onayı Kapat',
        ),
        content: Text(
          value
              ? 'Güvenilir olarak işaretlenen çalışanların yevmiye girişleri otomatik olarak onaylanacak. Emin misiniz?'
              : 'Otomatik onay kapatılacak. Tüm çalışanların yevmiye girişleri manuel onay gerektirecek. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hayır'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Evet'),
          ),
        ],
      ),
    );
  }
}
