import 'package:flutter/material.dart';
import '../../../../models/employee_reminder.dart';
import '../../../../models/notification_settings.dart';
import '../../../../services/attendance_check.dart';
import 'notification_state_mixin.dart';

/// Notification Settings ekranı için data operations mixin'i
///
/// Bu mixin, veri yükleme, kaydetme ve filtreleme işlemlerini yönetir.
mixin NotificationDataMixin<T extends StatefulWidget>
    on NotificationStateMixin<T> {
  /// Load workers from service
  Future<void> loadWorkers() async {
    setState(() {
      isLoadingWorkers = true;
    });

    try {
      final loadedWorkers = await workerService.getWorkers();
      setState(() {
        workers = loadedWorkers;
        filteredWorkers = loadedWorkers;
      });
    } catch (e) {
      showSnackBar('Çalışanlar yüklenirken bir hata oluştu');
    } finally {
      setState(() {
        isLoadingWorkers = false;
      });
    }
  }

  /// Filter workers and reminders by query
  void filterWorkers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredWorkers = workers;
        filteredReminders = reminders;
      } else {
        final lowerQuery = query.toLowerCase();
        filteredWorkers = workers
            .where(
              (worker) => worker.fullName.toLowerCase().contains(lowerQuery),
            )
            .toList();
        filteredReminders = reminders
            .where(
              (reminder) =>
                  reminder.workerName.toLowerCase().contains(lowerQuery),
            )
            .toList();
      }
    });
  }

  /// Load notification settings
  Future<void> loadSettings() async {
    debugPrint('🔄 _loadSettings başladı');

    setState(() {
      isLoading = true;
    });

    try {
      final userId = await notificationService.getCurrentUserId();
      debugPrint('👤 User ID: $userId');

      if (userId == null) {
        debugPrint('❌ User ID null');
        showSnackBar('Oturum bilgisi alınamadı');
        return;
      }

      final loadedSettings = await notificationService
          .getNotificationSettings();
      debugPrint('📥 Veritabanından gelen ayarlar: $loadedSettings');
      debugPrint(
        '📥 enabled: ${loadedSettings?.enabled}, time: ${loadedSettings?.time}',
      );

      if (loadedSettings != null) {
        debugPrint('✅ Ayarlar bulundu, state güncelleniyor');
        setState(() {
          settings = loadedSettings;
          isEnabled = loadedSettings.enabled;
          autoApproveTrusted = loadedSettings.autoApproveTrusted;
          attendanceRequestsEnabled = loadedSettings.attendanceRequestsEnabled;
          selectedTime = loadedSettings.time;
        });
        debugPrint(
          '✅ State güncellendi: isEnabled=$isEnabled, autoApproveTrusted=$autoApproveTrusted, attendanceRequestsEnabled=$attendanceRequestsEnabled, selectedTime=$selectedTime',
        );
      } else {
        debugPrint('⚠️ Ayarlar bulunamadı, varsayılan değerler kullanılıyor');
        setState(() {
          settings = null;
          isEnabled = false;
          autoApproveTrusted = false;
          attendanceRequestsEnabled = true;
          selectedTime = '18:00';
        });
      }
    } catch (e) {
      debugPrint('❌ Hata: $e');
      showSnackBar('Ayarlar yüklenirken bir hata oluştu');
    } finally {
      setState(() {
        isLoading = false;
      });
      debugPrint('✅ _loadSettings tamamlandı');
    }
  }

  /// Save notification settings
  Future<void> saveSettings() async {
    debugPrint(
      '💾 _saveSettings başladı - isEnabled: $isEnabled, autoApproveTrusted: $autoApproveTrusted, attendanceRequestsEnabled: $attendanceRequestsEnabled, selectedTime: $selectedTime',
    );

    setState(() {
      isLoading = true;
    });

    try {
      final userId = await notificationService.getCurrentUserId();
      debugPrint('👤 User ID: $userId');

      if (userId == null) {
        debugPrint('❌ User ID null');
        showSnackBar('Oturum bilgisi alınamadı');
        return;
      }

      final settingsToSave =
          settings ??
          NotificationSettings(
            userId: userId,
            time: selectedTime,
            enabled: isEnabled,
            autoApproveTrusted: autoApproveTrusted,
            attendanceRequestsEnabled: attendanceRequestsEnabled,
            lastUpdated: DateTime.now(),
          );

      final updatedSettings = NotificationSettings(
        id: settingsToSave.id,
        userId: userId,
        time: selectedTime,
        enabled: isEnabled,
        autoApproveTrusted: autoApproveTrusted,
        attendanceRequestsEnabled: attendanceRequestsEnabled,
        lastUpdated: DateTime.now(),
      );

      debugPrint(
        '💾 Kaydedilecek ayarlar: enabled=$isEnabled, autoApproveTrusted=$autoApproveTrusted, attendanceRequestsEnabled=$attendanceRequestsEnabled, time=$selectedTime',
      );

      final success = await notificationService.updateNotificationSettings(
        updatedSettings,
      );

      debugPrint('💾 Kaydetme sonucu: $success');

      if (success) {
        // Yeni bildirim sistemi ile hatırlatıcıyı zamanla veya iptal et
        if (isEnabled) {
          debugPrint('📅 Hatırlatıcı zamanlanıyor...');
          await scheduleAttendanceReminderWithNewSystem();
        } else {
          debugPrint('🚫 Hatırlatıcı iptal ediliyor...');
          await cancelAttendanceReminderWithNewSystem();
        }

        final hasAttendanceToday = await notificationService
            .hasAttendanceEntryForToday();
        final attendanceDoneLocally =
            await AttendanceCheck.isTodayAttendanceDone();

        if (hasAttendanceToday || attendanceDoneLocally) {
          showSnackBar(
            'Bildirim ayarları kaydedildi. Bugün için yevmiye girişi zaten yapılmış.',
          );
        } else if (isEnabled) {
          final now = DateTime.now();
          final timeParts = selectedTime.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final scheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            hour,
            minute,
          );

          if (scheduledTime.isBefore(now)) {
            showSnackBar(
              'Bildirim ayarları kaydedildi. Belirtilen saat geçtiği için bildirim yarın etkin olacak.',
            );
          } else {
            showSnackBar(
              'Bildirim ayarları kaydedildi. Bildirim bugün $selectedTime saatinde gönderilecek.',
            );
          }
        } else {
          showSnackBar(
            'Bildirim ayarları kaydedildi. Bildirimler devre dışı bırakıldı.',
          );
        }

        debugPrint('🔄 Ayarlar yeniden yükleniyor...');
        await loadSettings();
      } else {
        debugPrint('❌ Kaydetme başarısız');
        showSnackBar('Bildirim ayarları kaydedilirken bir hata oluştu');
      }
    } catch (e) {
      debugPrint('❌ Hata: $e');
      showSnackBar('Ayarlar kaydedilirken bir hata oluştu: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
      debugPrint('✅ _saveSettings tamamlandı');
    }
  }

  /// Schedule attendance reminder with new system
  Future<void> scheduleAttendanceReminderWithNewSystem() async {
    try {
      // Kullanıcı bilgilerini al
      final user = await authService.currentUser;
      if (user == null) {
        debugPrint('Kullanıcı bilgisi alınamadı');
        return;
      }

      final userId = user['id'] as int;
      final username = user['username'] as String;
      final firstName = user['first_name'] as String? ?? '';
      final lastName = user['last_name'] as String? ?? '';
      final fullName = '$firstName $lastName'.trim();

      // Saat bilgisini ayrıştır
      final timeParts = selectedTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Yeni bildirim servisi ile zamanla
      await notificationServiceV2.scheduleAttendanceReminder(
        userId: userId,
        username: username,
        fullName: fullName,
        time: TimeOfDay(hour: hour, minute: minute),
      );

      debugPrint('✅ Yevmiye hatırlatıcısı yeni sistem ile zamanlandı');
    } catch (e) {
      debugPrint('❌ Yevmiye hatırlatıcısı zamanlanırken hata: $e');
    }
  }

  /// Cancel attendance reminder with new system
  Future<void> cancelAttendanceReminderWithNewSystem() async {
    try {
      await notificationServiceV2.cancelNotification(
        1,
      ); // NotificationIds.attendanceReminder
      debugPrint('✅ Yevmiye hatırlatıcısı iptal edildi');
    } catch (e) {
      debugPrint('❌ Yevmiye hatırlatıcısı iptal edilirken hata: $e');
    }
  }

  /// Load reminders
  Future<void> loadReminders() async {
    final requestId = ++remindersLoadRequestId;
    setState(() {
      isLoadingReminders = true;
    });

    try {
      final loadedReminders = await reminderService.getEmployeeReminders();

      if (!mounted || requestId != remindersLoadRequestId) return;

      setState(() {
        reminders = loadedReminders
            .where(
              (r) => r.id == null || !pendingDeleteReminderIds.contains(r.id),
            )
            .toList();
        filteredReminders = reminders;
      });
    } catch (e) {
      showSnackBar('Hatırlatıcılar yüklenirken bir hata oluştu');
    } finally {
      if (!mounted) return;
      setState(() {
        isLoadingReminders = false;
      });
    }
  }

  /// Delete reminder with optimistic update
  Future<void> deleteReminderOptimistic(
    int listIndex,
    EmployeeReminder reminder,
  ) async {
    if (reminder.id == null) return;

    final reminderId = reminder.id!;

    pendingDeleteReminderIds.add(reminderId);

    setState(() {
      reminders.removeWhere((r) => r.id == reminderId);
    });

    try {
      final success = await reminderService
          .deleteEmployeeReminderWithNotification(reminderId);
      if (success) {
        pendingDeleteReminderIds.remove(reminderId);
        showSnackBar('Hatırlatıcı silindi');
        loadReminders();
      } else {
        pendingDeleteReminderIds.remove(reminderId);
        setState(() {
          final safeIndex = listIndex.clamp(0, reminders.length);
          reminders.insert(safeIndex, reminder);
        });
        showSnackBar('Hatırlatıcı silinirken bir hata oluştu');
      }
    } catch (e) {
      pendingDeleteReminderIds.remove(reminderId);
      setState(() {
        final safeIndex = listIndex.clamp(0, reminders.length);
        reminders.insert(safeIndex, reminder);
      });
      showSnackBar('Hatırlatıcı silinirken bir hata oluştu');
    }
  }
}
