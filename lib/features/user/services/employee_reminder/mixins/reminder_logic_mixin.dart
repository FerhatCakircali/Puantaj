import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../../../../models/employee_reminder.dart';
import '../../../../../../models/notification_payload.dart';
import '../../../../../../services/notification_service.dart';
import 'reminder_data_mixin.dart';

/// Çalışan hatırlatıcıları için bildirim zamanlama ve mantık işlemlerini yöneten mixin
mixin ReminderLogicMixin on ReminderDataMixin {
  final NotificationService _notificationService = NotificationService();

  /// Hatırlatıcı için bildirim zamanla
  Future<void> scheduleReminderNotification(EmployeeReminder reminder) async {
    try {
      final now = DateTime.now();
      debugPrint(
        'Hatırlatıcı zamanlaması başlatılıyor: ID=${reminder.id}, Tarih=${reminder.reminderDate}, Şimdi=$now',
      );

      // Tarihin gerçekçi olup olmadığını kontrol et
      if (reminder.reminderDate.difference(now).inDays > 30) {
        debugPrint(
          'UYARI: Hatırlatıcı tarihi çok uzak bir gelecekte (${reminder.reminderDate}), muhtemelen UTC dönüşüm hatası!',
        );

        await _scheduleTestNotification(reminder, now);
        return;
      }

      // Normal bildirim süreci
      if (reminder.reminderDate.isBefore(now)) {
        debugPrint(
          'Hatırlatıcı tarihi geçmiş, bildirim zamanlanmadı: ${reminder.reminderDate}',
        );
        return;
      }

      final userData = await getUserData(reminder.userId);
      final username = userData['username'] as String? ?? 'kullanıcı';
      final firstName = userData['first_name'] as String? ?? '';
      final lastName = userData['last_name'] as String? ?? '';
      final fullName = '$firstName $lastName'.trim();

      final notificationId =
          reminder.id ?? DateTime.now().millisecondsSinceEpoch;

      // Yeni payload formatı kullanılıyor
      // ignore: unused_local_variable
      final payload = NotificationPayload(
        type: NotificationType.employeeReminder,
        userId: reminder.userId,
        username: username,
        fullName: fullName,
        reminderId: reminder.id,
      ).toJson();

      final scheduledDate = reminder.reminderDate;
      debugPrint('Hatırlatıcı tarihi: $scheduledDate');

      try {
        // Eski bildirim servisi kullanımı - artık EmployeeReminderService yeni sistemi kullanıyor
        debugPrint(
          'scheduleNotification çağrısı atlandı - yeni sistem kullanılıyor',
        );
        /*
        await _notificationService.scheduleNotification(
          id: notificationId,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          payload: payload,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        */

        debugPrint(
          'Çalışan hatırlatıcısı için bildirim zamanlandı: ID=$notificationId, Tarih=$scheduledDate',
        );

        if (reminder.id != null) {
          await scheduleReminderCheckNotifications(reminder);
        }
      } catch (e) {
        debugPrint('Zamanlanmış bildirim oluşturulurken hata: $e');

        try {
          await _manualScheduleNotification(reminder);
        } catch (e2) {
          debugPrint('Manuel bildirim de başarısız: $e2');
        }
      }
    } catch (e) {
      debugPrint('Hatırlatıcı bildirimi zamanlanırken hata: $e');
    }
  }

  /// Test bildirimi zamanla (UTC dönüşüm hatası durumunda)
  Future<void> _scheduleTestNotification(
    EmployeeReminder reminder,
    DateTime now,
  ) async {
    final userData = await getUserData(reminder.userId);
    final username = userData['username'] as String? ?? 'kullanıcı';
    final firstName = userData['first_name'] as String? ?? '';
    final lastName = userData['last_name'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();

    final testScheduleDate = now.add(const Duration(minutes: 2));

    try {
      // Yeni payload formatı kullanılıyor
      // ignore: unused_local_variable
      final payload = NotificationPayload(
        type: NotificationType.employeeReminder,
        userId: reminder.userId,
        username: username,
        fullName: fullName,
        reminderId: reminder.id,
      ).toJson();

      // Eski bildirim servisi kullanımı - yeni sistem kullanılıyor
      debugPrint(
        'scheduleNotification çağrısı atlandı - yeni sistem kullanılıyor',
      );
      /*
      await _notificationService.scheduleNotification(
        id: reminder.id ?? DateTime.now().millisecondsSinceEpoch,
        title: 'Hatırlatıcı - ${reminder.workerName} ($fullName)',
        body: reminder.message,
        scheduledDate: testScheduleDate,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      */

      debugPrint('Düzeltilmiş bildirim zamanlandı: Tarih=$testScheduleDate');
    } catch (e) {
      debugPrint('Bildirim zamanlanırken hata: $e');
    }
  }

  /// Hatırlatıcı zamanını kontrol eden ara bildirimler gönder
  Future<void> scheduleReminderCheckNotifications(
    EmployeeReminder reminder,
  ) async {
    try {
      final now = DateTime.now();
      final timeUntilReminder = reminder.reminderDate.difference(now);

      final userData = await getUserData(reminder.userId);
      final username = userData['username'] as String? ?? 'kullanıcı';
      final firstName = userData['first_name'] as String? ?? '';
      final lastName = userData['last_name'] as String? ?? '';
      final fullName = '$firstName $lastName'.trim();

      // Eğer 24 saatten fazla varsa, günlük kontrol bildirimi planla
      if (timeUntilReminder.inHours > 24) {
        final checkDate = now.add(const Duration(days: 1));
        final checkTime = DateTime(
          checkDate.year,
          checkDate.month,
          checkDate.day,
          12,
          0,
          0,
        );

        // Yeni payload formatı kullanılıyor
        // ignore: unused_local_variable
        final payload = NotificationPayload(
          type: NotificationType.employeeReminder,
          userId: reminder.userId,
          username: username,
          fullName: fullName,
          reminderId: reminder.id,
        ).toJson();

        // Eski bildirim servisi kullanımı - yeni sistem kullanılıyor
        debugPrint(
          'scheduleNotification çağrısı atlandı - yeni sistem kullanılıyor',
        );
        /*
        await _notificationService.scheduleNotification(
          id: reminder.id! + 200000,
          title: 'Hatırlatıcı Kontrolü - ${reminder.workerName} ($fullName)',
          body: '${reminder.message} için hatırlatıcınız hala aktif',
          scheduledDate: checkTime,
          payload: payload,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        */

        debugPrint('Günlük kontrol bildirimi zamanlandı: $checkTime');
      }

      // Eğer 1 saatten fazla, 24 saatten az varsa, bir saat önce kontrol bildirimi planla
      if (timeUntilReminder.inHours > 1 && timeUntilReminder.inHours <= 24) {
        final oneHourBefore = reminder.reminderDate.subtract(
          const Duration(hours: 1),
        );

        // Yeni payload formatı kullanılıyor
        // ignore: unused_local_variable
        final payload = NotificationPayload(
          type: NotificationType.employeeReminder,
          userId: reminder.userId,
          username: username,
          fullName: fullName,
          reminderId: reminder.id,
        ).toJson();

        // Eski bildirim servisi kullanımı - yeni sistem kullanılıyor
        debugPrint(
          'scheduleNotification çağrısı atlandı - yeni sistem kullanılıyor',
        );
        /*
        await _notificationService.scheduleNotification(
          id: reminder.id! + 300000,
          title: 'Yaklaşan Hatırlatıcı - ${reminder.workerName} ($fullName)',
          body: '${reminder.message} - 1 saat kaldı',
          scheduledDate: oneHourBefore,
          payload: payload,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        */

        debugPrint('1 saat öncesi bildirim zamanlandı: $oneHourBefore');
      }
    } catch (e) {
      debugPrint('Kontrol bildirimleri zamanlanırken hata: $e');
    }
  }

  /// Manuel olarak bildirim gönderme (acil durum için)
  Future<void> _manualScheduleNotification(EmployeeReminder reminder) async {
    try {
      final now = DateTime.now();
      if (reminder.reminderDate.isBefore(now)) {
        debugPrint(
          'Manuel bildirim için tarih geçmiş: ${reminder.reminderDate}',
        );
        return;
      }

      final userId = reminder.userId;
      final userData = await getUserData(userId);

      final username = userData['username'] as String;
      final firstName = userData['first_name'] as String;
      final lastName = userData['last_name'] as String;
      final fullName = '$firstName $lastName';

      final title = 'Çalışan Hatırlatıcısı - ${reminder.workerName}';
      final body = reminder.message;

      final scheduledDate = tz.TZDateTime.from(reminder.reminderDate, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'employee_reminders',
        'Çalışan Hatırlatıcıları',
        channelDescription: 'Çalışanlarla ilgili hatırlatıcılar',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Yeni payload formatı kullanılıyor
      // ignore: unused_local_variable
      final payload = NotificationPayload(
        type: NotificationType.employeeReminder,
        userId: userId,
        username: username,
        fullName: fullName,
        reminderId: reminder.id,
      ).toJson();

      await _notificationService.flutterLocalNotificationsPlugin.zonedSchedule(
        id: reminder.id!,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('Manuel bildirim başarıyla zamanlandı: ID=${reminder.id}');
    } catch (e) {
      debugPrint('Manuel bildirim zamanlanırken hata: $e');
    }
  }

  /// Bildirimi iptal et
  Future<void> cancelReminderNotification(EmployeeReminder reminder) async {
    if (reminder.id != null) {
      await _notificationService.cancelNotification(reminder.id!);
    }
  }
}
