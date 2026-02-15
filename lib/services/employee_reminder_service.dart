import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart';
import '../models/employee_reminder.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class EmployeeReminderService {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  // Kullanıcının tüm çalışan hatırlatıcılarını getir
  Future<List<EmployeeReminder>> getEmployeeReminders({
    bool includeCompleted = false,
  }) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Veritabanından hatırlatıcıları çek
      final query = supabase
          .from('employee_reminders')
          .select()
          .eq('user_id', userId);

      // Tamamlanmış olanları dahil etme seçeneği
      if (!includeCompleted) {
        query.eq('is_completed', 0);
      }

      // Tarihe göre sırala (yakın tarihler önce)
      query.order('reminder_date', ascending: true);

      final List<dynamic> data = await query;

      // Map'leri EmployeeReminder nesnelerine dönüştür
      return data.map((item) => EmployeeReminder.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Çalışan hatırlatıcıları alınırken hata: $e');
      return [];
    }
  }

  // Belirli bir çalışanın hatırlatıcılarını getir
  Future<List<EmployeeReminder>> getEmployeeRemindersByWorkerId(
    int workerId, {
    bool includeCompleted = false,
  }) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Veritabanından hatırlatıcıları çek
      final query = supabase
          .from('employee_reminders')
          .select()
          .eq('user_id', userId)
          .eq('worker_id', workerId);

      // Tamamlanmış olanları dahil etme seçeneği
      if (!includeCompleted) {
        query.eq('is_completed', 0);
      }

      // Tarihe göre sırala (yakın tarihler önce)
      query.order('reminder_date', ascending: true);

      final List<dynamic> data = await query;

      // Map'leri EmployeeReminder nesnelerine dönüştür
      return data.map((item) => EmployeeReminder.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Çalışanın hatırlatıcıları alınırken hata: $e');
      return [];
    }
  }

  // Hatırlatıcı ekle
  Future<EmployeeReminder?> addEmployeeReminder(
    EmployeeReminder reminder,
  ) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Hatırlatıcıyı veritabanına ekle
      final data = await supabase
          .from('employee_reminders')
          .insert(reminder.toMap())
          .select()
          .single();

      final newReminder = EmployeeReminder.fromMap(data);

      // Hatırlatıcı için bildirim zamanla
      await _scheduleReminderNotification(newReminder);

      return newReminder;
    } catch (e) {
      debugPrint('Çalışan hatırlatıcısı eklenirken hata: $e');
      return null;
    }
  }

  // Hatırlatıcıyı güncelle
  Future<bool> updateEmployeeReminder(EmployeeReminder reminder) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Hatırlatıcıyı veritabanında güncelle
      await supabase
          .from('employee_reminders')
          .update(reminder.toMap())
          .eq('id', reminder.id!)
          .eq('user_id', userId);

      // Eğer hatırlatıcı tamamlanmadıysa, bildirimi yeniden zamanla
      if (!reminder.isCompleted) {
        await _scheduleReminderNotification(reminder);
      } else {
        // Tamamlandıysa bildirimi iptal et
        await _cancelReminderNotification(reminder);
      }

      return true;
    } catch (e) {
      debugPrint('Çalışan hatırlatıcısı güncellenirken hata: $e');
      return false;
    }
  }

  // Hatırlatıcıyı sil
  Future<bool> deleteEmployeeReminder(int reminderId) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Önce hatırlatıcıyı almaya çalış.
      // Bazı durumlarda (ör. yarış durumu / RLS / veri tutarsızlığı) select başarısız olabilir.
      // Bu durumda bile bildirimi iptal edip delete'i denemek istiyoruz.
      EmployeeReminder? reminder;
      try {
        final data = await supabase
            .from('employee_reminders')
            .select()
            .eq('id', reminderId)
            .eq('user_id', userId)
            .single();
        reminder = EmployeeReminder.fromMap(data);
      } catch (e) {
        debugPrint(
          'Silme öncesi hatırlatıcı bilgisi alınamadı (id=$reminderId). Yine de silme denenecek. Hata: $e',
        );
      }

      // Bildirimi iptal et
      // Not: Hatırlatıcı bilgisi yoksa, sadece id ile iptal etmek yeterli.
      try {
        if (reminder != null) {
          await _cancelReminderNotification(reminder);
        } else {
          await _notificationService.cancelNotification(reminderId);
        }
      } catch (e) {
        debugPrint(
          'Silme sırasında bildirim iptal edilemedi (id=$reminderId): $e',
        );
      }

      // Hatırlatıcıyı veritabanından sil
      await supabase
          .from('employee_reminders')
          .delete()
          .eq('id', reminderId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      debugPrint('Çalışan hatırlatıcısı silinirken hata: $e');
      return false;
    }
  }

  // Hatırlatıcıyı tamamlandı olarak işaretle
  Future<bool> markReminderAsCompleted(int reminderId) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Hatırlatıcıyı tamamlandı olarak güncelle
      await supabase
          .from('employee_reminders')
          .update({'is_completed': 1})
          .eq('id', reminderId)
          .eq('user_id', userId);

      // Bildirimi iptal et
      await _notificationService.cancelNotification(reminderId);

      return true;
    } catch (e) {
      debugPrint(
        'Çalışan hatırlatıcısı tamamlandı olarak işaretlenirken hata: $e',
      );
      return false;
    }
  }

  // Hatırlatıcı için bildirim zamanla
  Future<void> _scheduleReminderNotification(EmployeeReminder reminder) async {
    try {
      // Eğer hatırlatıcı tarihi geçmişse bildirim gönderme
      final now = DateTime.now();
      debugPrint(
        'Hatırlatıcı zamanlaması başlatılıyor: ID=${reminder.id}, Tarih=${reminder.reminderDate}, Şimdi=$now',
      );

      // Tarihin gerçekçi olup olmadığını kontrol et (muhtemel UTC-yerel dönüşüm hatası)
      if (reminder.reminderDate.difference(now).inDays > 30) {
        debugPrint(
          'UYARI: Hatırlatıcı tarihi çok uzak bir gelecekte (${reminder.reminderDate}), muhtemelen UTC dönüşüm hatası!',
        );

        // Kullanıcı bilgilerini alalım
        final userData = await _getUserData(reminder.userId);
        final username = userData['username'] as String? ?? 'kullanıcı';
        final firstName = userData['first_name'] as String? ?? '';
        final lastName = userData['last_name'] as String? ?? '';
        final fullName = '$firstName $lastName'.trim();

        // Düzeltilmiş bir tarih için bildirim zamanla (2 dakika sonra)
        final testScheduleDate = now.add(const Duration(minutes: 2));

        // Bildirimi zamanla
        try {
          // NotificationPayload kullanarak payload oluştur
          final payload = NotificationPayload(
            type:
                'employee_reminder_' +
                (reminder.id != null ? reminder.id.toString() : '0'),
            userId: reminder.userId,
            username: username,
            fullName: fullName,
            reminderId: reminder.id,
          ).toJsonString();

          await _notificationService.scheduleNotification(
            id: (reminder.id != null)
                ? reminder.id!
                : DateTime.now().millisecondsSinceEpoch,
            title: 'Hatırlatıcı - ${reminder.workerName} (${fullName})',
            body: reminder.message,
            scheduledDate: testScheduleDate,
            payload: payload,
            matchDateTimeComponents:
                DateTimeComponents.time, // Hesaplar arası çalışması için önemli
          );

          debugPrint(
            'Düzeltilmiş bildirim zamanlandı: Tarih=$testScheduleDate',
          );
        } catch (e) {
          debugPrint('Bildirim zamanlanırken hata: $e');
        }

        return;
      }

      // Normal bildirim süreci
      if (reminder.reminderDate.isBefore(now)) {
        debugPrint(
          'Hatırlatıcı tarihi geçmiş, bildirim zamanlanmadı: ${reminder.reminderDate}',
        );
        return;
      }

      // Kullanıcı bilgilerini alalım
      final userData = await _getUserData(reminder.userId);
      final username = userData['username'] as String? ?? 'kullanıcı';
      final firstName = userData['first_name'] as String? ?? '';
      final lastName = userData['last_name'] as String? ?? '';
      final fullName = '$firstName $lastName'.trim();

      // Bildirim başlığı ve içeriği
      final title = '${reminder.workerName} için hatırlatıcı (${fullName})';
      final body = reminder.message;

      // Bildirim ID'si olarak hatırlatıcı ID'sini kullan
      final notificationId = reminder.id != null
          ? reminder.id!
          : DateTime.now().millisecondsSinceEpoch;

      // NotificationPayload kullanarak payload oluştur
      final payload = NotificationPayload(
        type:
            'employee_reminder_' +
            (reminder.id != null ? reminder.id.toString() : '0'),
        userId: reminder.userId,
        username: username,
        fullName: fullName,
        reminderId: reminder.id,
      ).toJsonString();

      // Hatırlatıcı tarihi
      final scheduledDate = reminder.reminderDate;
      debugPrint('Hatırlatıcı tarihi: $scheduledDate');

      // Bildirimi zamanla
      try {
        // NotificationService üzerinden zamanla
        await _notificationService.scheduleNotification(
          id: notificationId,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          payload: payload,
          matchDateTimeComponents:
              DateTimeComponents.time, // Hesaplar arası çalışması için önemli
        );

        debugPrint(
          'Çalışan hatırlatıcısı için bildirim zamanlandı: ID=$notificationId, Tarih=$scheduledDate',
        );

        // Kontrol bildirimlerini zamanla
        if (reminder.id != null) {
          await _scheduleReminderCheckNotifications(reminder);
        }
      } catch (e) {
        debugPrint('Zamanlanmış bildirim oluşturulurken hata: $e');

        // Manuel yöntem ile tekrar dene
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

  // Kullanıcı bilgilerini al
  Future<Map<String, dynamic>> _getUserData(int userId) async {
    try {
      final data = await supabase
          .from('users')
          .select('username, first_name, last_name')
          .eq('id', userId)
          .single();

      if (data != null) {
        return data;
      }
    } catch (e) {
      debugPrint('Kullanıcı bilgileri alınırken hata: $e');
    }

    // Varsayılan değer
    return {'username': 'kullanıcı', 'first_name': '', 'last_name': ''};
  }

  // Hatırlatıcı zamanını kontrol eden ara bildirimler gönder
  Future<void> _scheduleReminderCheckNotifications(
    EmployeeReminder reminder,
  ) async {
    try {
      final now = DateTime.now();
      final timeUntilReminder = reminder.reminderDate.difference(now);

      // Kullanıcı bilgilerini alalım
      final userData = await _getUserData(reminder.userId);
      final username = userData['username'] as String? ?? 'kullanıcı';
      final firstName = userData['first_name'] as String? ?? '';
      final lastName = userData['last_name'] as String? ?? '';
      final fullName = '$firstName $lastName'.trim();

      // Eğer 24 saatten fazla varsa, günlük kontrol bildirimi planla
      if (timeUntilReminder.inHours > 24) {
        // Yarın için bir kontrol bildirimi planla
        final checkDate = now.add(const Duration(days: 1));
        final checkTime = DateTime(
          checkDate.year,
          checkDate.month,
          checkDate.day,
          12,
          0,
          0, // Öğlen 12:00
        );

        // NotificationPayload kullanarak payload oluştur
        final payload = NotificationPayload(
          type:
              'employee_reminder_check_' +
              (reminder.id != null ? reminder.id.toString() : '0'),
          userId: reminder.userId,
          username: username,
          fullName: fullName,
          reminderId: reminder.id,
        ).toJsonString();

        await _notificationService.scheduleNotification(
          id: reminder.id! + 200000, // Farklı bir ID kullan
          title: 'Hatırlatıcı Kontrolü - ${reminder.workerName} (${fullName})',
          body: '${reminder.message} için hatırlatıcınız hala aktif',
          scheduledDate: checkTime,
          payload: payload,
          matchDateTimeComponents:
              DateTimeComponents.time, // Hesaplar arası çalışması için önemli
        );

        debugPrint(
          'Günlük kontrol bildirimi zamanlandı: ${checkTime.toString()}',
        );
      }

      // Eğer 1 saatten fazla, 24 saatten az varsa, bir saat önce kontrol bildirimi planla
      if (timeUntilReminder.inHours > 1 && timeUntilReminder.inHours <= 24) {
        final oneHourBefore = reminder.reminderDate.subtract(
          const Duration(hours: 1),
        );

        // NotificationPayload kullanarak payload oluştur
        final payload = NotificationPayload(
          type:
              'employee_reminder_soon_' +
              (reminder.id != null ? reminder.id.toString() : '0'),
          userId: reminder.userId,
          username: username,
          fullName: fullName,
          reminderId: reminder.id,
        ).toJsonString();

        // Bir saat önce bildirim
        await _notificationService.scheduleNotification(
          id: reminder.id! + 300000, // Farklı bir ID kullan
          title: 'Yaklaşan Hatırlatıcı - ${reminder.workerName} (${fullName})',
          body: '${reminder.message} - 1 saat kaldı',
          scheduledDate: oneHourBefore,
          payload: payload,
          matchDateTimeComponents:
              DateTimeComponents.time, // Hesaplar arası çalışması için önemli
        );

        debugPrint(
          '1 saat öncesi bildirim zamanlandı: ${oneHourBefore.toString()}',
        );
      }
    } catch (e) {
      debugPrint('Kontrol bildirimleri zamanlanırken hata: $e');
    }
  }

  // Manuel olarak bildirim gönderme (acil durum için)
  Future<void> _manualScheduleNotification(EmployeeReminder reminder) async {
    try {
      final now = DateTime.now();
      // Eğer tarih gelecekteyse
      if (reminder.reminderDate.isAfter(now)) {
        // Kullanıcı bilgilerini al
        final userId = reminder.userId;
        final userData = await supabase
            .from('users')
            .select('username, first_name, last_name')
            .eq('id', userId)
            .single();

        final username = userData['username'] as String;
        final firstName = userData['first_name'] as String;
        final lastName = userData['last_name'] as String;
        final fullName = '$firstName $lastName';

        // Bildirim başlığı ve içeriği
        final title =
            'Çalışan Hatırlatıcısı - ${reminder.workerName} (${fullName})';
        final body = reminder.message;

        // Hatırlatıcı zamanını TZDateTime'a çevir
        final scheduledDate = tz.TZDateTime.from(
          reminder.reminderDate,
          tz.local,
        );

        // AndroidNotificationDetails oluştur
        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
              'employee_reminders',
              'Çalışan Hatırlatıcıları',
              channelDescription: 'Çalışanlarla ilgili hatırlatıcılar',
              importance: Importance.high,
              priority: Priority.high,
            );

        // iOS bildirim detayları
        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        // Genel bildirim detayları
        const NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        // NotificationPayload kullanarak payload oluştur
        final payload = NotificationPayload(
          type:
              'employee_reminder_' +
              (reminder.id != null ? reminder.id.toString() : '0'),
          userId: userId,
          username: username,
          fullName: fullName,
          reminderId: reminder.id,
        ).toJsonString();

        // Bildirimi zamanla
        await _notificationService.flutterLocalNotificationsPlugin
            .zonedSchedule(
              reminder.id!, // Her hatırlatıcı için benzersiz ID
              title,
              body,
              scheduledDate,
              notificationDetails,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              payload: payload,
              matchDateTimeComponents: DateTimeComponents
                  .time, // Hesaplar arası çalışması için önemli
            );

        debugPrint('Manuel bildirim başarıyla zamanlandı: ID=${reminder.id}');
      } else {
        debugPrint(
          'Manuel bildirim için tarih geçmiş: ${reminder.reminderDate}',
        );
      }
    } catch (e) {
      debugPrint('Manuel bildirim zamanlanırken hata: $e');
    }
  }

  // Bildirimi iptal et
  Future<void> _cancelReminderNotification(EmployeeReminder reminder) async {
    if (reminder.id != null) {
      await _notificationService.cancelNotification(reminder.id!);
    }
  }

  // Tüm hatırlatıcıları yeniden zamanla
  Future<void> rescheduleAllReminders() async {
    try {
      // Tamamlanmamış hatırlatıcıları al
      final reminders = await getEmployeeReminders(includeCompleted: false);

      // Her hatırlatıcı için bildirim zamanla
      for (final reminder in reminders) {
        await _scheduleReminderNotification(reminder);
      }

      debugPrint(
        'Tüm çalışan hatırlatıcıları yeniden zamanlandı: ${reminders.length} adet',
      );
    } catch (e) {
      debugPrint('Hatırlatıcılar yeniden zamanlanırken hata: $e');
    }
  }
}
