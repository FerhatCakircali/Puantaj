import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/notification_settings.dart';
import 'attendance_service.dart';
import 'attendance_check.dart';
import 'auth_service.dart';

// Bildirim tıklama olayını dinlemek için global değişken
final StreamController<String> notificationClickStream = StreamController<String>.broadcast();

// Kullanıcı kimliği ve hesap bilgisini içeren gelişmiş payload yapısı
class NotificationPayload {
  final String type; // 'attendance_reminder' veya 'employee_reminder_ID'
  final int userId; // Hangi kullanıcıya ait olduğu
  final String username; // Kullanıcı adı
  final String fullName; // Tam adı (first_name + last_name)
  final int? reminderId; // Çalışan hatırlatıcısı ID'si (varsa)

  NotificationPayload({
    required this.type,
    required this.userId,
    required this.username,
    required this.fullName,
    this.reminderId,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'user_id': userId,
    'username': username,
    'full_name': fullName,
    if (reminderId != null) 'reminder_id': reminderId,
  };

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      type: json['type'],
      userId: json['user_id'],
      username: json['username'],
      fullName: json['full_name'],
      reminderId: json['reminder_id'],
    );
  }

  // JSON string'e dönüştürme
  String toJsonString() => jsonEncode(toJson());

  // JSON string'den oluşturma
  static NotificationPayload? fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return NotificationPayload.fromJson(json);
    } catch (e) {
      print('NotificationPayload ayrıştırma hatası: $e');
      return null;
    }
  }
}

// Arka planda bildirim alındığında çalışacak top-level fonksiyon
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('Arka planda bildirim tıklandı (static): ${notificationResponse.payload}');
  
  // Bildirim ID'sini al
  int notificationId = notificationResponse.id ?? 0;
  
  // Bildirimi kapat - arka planda tıklamada otomatik olarak kapat
  FlutterLocalNotificationsPlugin().cancel(notificationId);
  print('Bildirim otomatik olarak kapatıldı (ID: $notificationId)');
  
  // Bildirimin payload'ını sakla (uygulama başlatıldığında kullanılmak üzere)
  if (notificationResponse.payload != null) {
    _saveLaunchPayloadStatic(notificationResponse.payload!);
    
    // Bildirimin tıklandığını stream'e gönder
    notificationClickStream.add(notificationResponse.payload!);
    
    // Payload'ı ayrıştır
    final payload = NotificationPayload.fromJsonString(notificationResponse.payload!);
    
    // Eğer bu bir yevmiye hatırlatıcısı ise, bildirimi veritabanından da sil
    if (payload?.type == 'attendance_reminder' || payload?.type == 'daily_attendance_reminder') {
      // Arka plan işlemi olduğu için doğrudan veritabanı işlemi yapmadan
      // SharedPreferences üzerinden işlem yapmak daha güvenli
      _clearNotificationRecordStatic();
    }
  }
}

// Bildirimden başlatma bilgisini kaydet
@pragma('vm:entry-point')
Future<void> _saveLaunchPayloadStatic(String payload) async {
  try {
    // Payload'ı kaydet
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_notification_payload', payload);
    await prefs.setBool('launched_from_notification', true);
    
    print('Bildirim başlatma bilgisi kaydedildi: $payload');
  } catch (e) {
    print('Bildirim başlatma bilgisi kaydedilirken hata: $e');
  }
}

// Statik bildirim temizleme metodu (arka plan işlemleri için)
@pragma('vm:entry-point')
Future<void> _clearNotificationRecordStatic() async {
  try {
    // Bugünün tarihini al
    final now = DateTime.now();
    String todayKey = 'notification_sent_${now.year}_${now.month}_${now.day}';
    
    // SharedPreferences üzerinden kaydı sil
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(todayKey);
    
    print('Bildirim kaydı statik olarak silindi: $todayKey');
  } catch (e) {
    print('Bildirim kaydı statik olarak silinirken hata: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final AuthService _authService = AuthService();
  final AttendanceService _attendanceService = AttendanceService();

  NotificationService._internal();

  Future<void> init() async {
    try {
    // Timezone ayarlarını başlat
    tz.initializeTimeZones();
    
      // Türkiye saat dilimini ayarla
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
        print('Saat dilimi ayarlandı: ${tz.local.name}');
    } catch (e) {
      print('Saat dilimi ayarlanırken hata: $e');
        // Varsayılan UTC kullan
      tz.setLocalLocation(tz.UTC);
      print('Hata nedeniyle UTC saat dilimine geçildi');
    }

      // Flutter Local Notifications eklentisini başlat
      const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/launcher_icon');
        
      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        
      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      // Bildirim plugin'ini başlat
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      // Bildirim izinlerini kontrol et
      await _checkAndRequestNotificationPermissions();
      
      // Android'de bildirim kanallarını oluştur
      if (Platform.isAndroid) {
        // Xiaomi cihazlar için özel high-priority channel
        const AndroidNotificationChannel xiomiChannel = AndroidNotificationChannel(
          'xiaomi_high_importance_channel',
          'Yüksek Öncelikli Bildirimler (Xiaomi)',
          description: 'Xiaomi cihazlar için özel bildirim kanalı',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
          enableLights: true,
        );
        
        // Android için ana bildirim kanallarını oluştur
        const AndroidNotificationChannel attendanceChannel = AndroidNotificationChannel(
          'attendance_reminder',
          'Yevmiye Hatırlatıcısı',
          description: 'Günlük yevmiye girişi hatırlatıcısı',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        );
        
        const AndroidNotificationChannel employeeReminderChannel = AndroidNotificationChannel(
          'employee_reminders',
          'Çalışan Hatırlatıcıları',
          description: 'Çalışanlar için özel hatırlatıcılar',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        );
        
        const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
          'test_channel',
          'Test Bildirimleri',
          description: 'Test bildirimleri için kanal',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        );
          
        // Kanalları FlutterLocalNotificationsPlugin aracılığıyla oluştur
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>();
                    
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(xiomiChannel);
          await androidPlugin.createNotificationChannel(attendanceChannel);
          await androidPlugin.createNotificationChannel(employeeReminderChannel);
          await androidPlugin.createNotificationChannel(testChannel);
          
          // İzinleri kontrol et ve rapor et
          final bool? areNotificationsEnabled = await androidPlugin.areNotificationsEnabled();
          debugPrint('Android bildirim izinleri: $areNotificationsEnabled');
        }
      }
      
      // Uygulama açıldığında bildirimleri kontrol et
      await checkLaunchedFromNotification();
      
      print('NotificationService başarıyla başlatıldı');
      
    } catch (e, stack) {
      print('NotificationService başlatılırken hata: $e');
      print('Stack trace: $stack');
    }
  }
  
  // Bildirime tıklandığında çalışacak metod
  void _onNotificationTapped(NotificationResponse response) {
    print('Bildirime tıklandı: ${response.payload}');
        if (response.payload != null) {
          _handleNotificationPayload(response.payload!);
        }
      }

  // Bildirim içeriğini işleme
  void _handleNotificationPayload(String jsonPayload) {
    print('Bildirim içeriği işleniyor: $jsonPayload');
    
    try {
      // Eski format payload (geriye dönük uyumluluk için)
      if (jsonPayload == 'attendance_reminder' || jsonPayload == 'daily_attendance_reminder') {
        print('Eski format yevmiye bildirimi tespit edildi');
    
        // Bildirimi stream'e ilet (UI yönlendirmesi için)
        notificationClickStream.add(jsonPayload);
      
        // Bildirimi veritabanından sil
        _clearNotificationRecord();
        return;
      }
      
      // Yeni format payload (JSON)
      final payload = NotificationPayload.fromJsonString(jsonPayload);
      if (payload == null) {
        print('Payload ayrıştırılamadı, ham veriyi kullan');
        notificationClickStream.add(jsonPayload);
        return;
      }
    
    // Bildirimi stream'e ilet (UI yönlendirmesi için)
      notificationClickStream.add(jsonPayload);
    
      // Bildirim tipine göre işlem yap
      if (payload.type == 'attendance_reminder' || payload.type == 'daily_attendance_reminder') {
        // Yevmiye bildirimi
      _clearNotificationRecord();
      } else if (payload.type.startsWith('employee_reminder_') || 
                payload.type.startsWith('employee_reminder_check_') || 
                payload.type.startsWith('employee_reminder_soon_') || 
                payload.type.startsWith('employee_reminder_confirmation_')) {
        // Çalışan hatırlatıcısı
        if (payload.reminderId != null) {
          _saveReminderIdToPrefs(payload.reminderId!);
        } else if (payload.type.contains('_')) {
          // ID'yi tip bilgisinden çıkarmayı dene
          try {
            final parts = payload.type.split('_');
            if (parts.length >= 3) {
              final idStr = parts.last;
              final id = int.parse(idStr);
              _saveReminderIdToPrefs(id);
            }
          } catch (e) {
            print('Bildirim tipinden ID çıkarılamadı: ${payload.type}');
          }
        }
      }
      } catch (e) {
      print('Bildirim içeriği işlenirken hata: $e');
      // Herhangi bir hata durumunda ham payloadı ilet
      notificationClickStream.add(jsonPayload);
    }
  }

  // Hatırlatıcı ID'sini SharedPreferences'a kaydet
  Future<void> _saveReminderIdToPrefs(int reminderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('active_employee_reminder_id', reminderId);
      print('Hatırlatıcı ID SharedPreferences\'a kaydedildi: $reminderId');
    } catch (e) {
      print('Hatırlatıcı ID kaydedilirken hata: $e');
    }
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      print('Bildirim izni verildi');
    } else {
      print('Bildirim izni reddedildi');
    }
    
    // Android cihazlarda tam alarm izni iste (API 31+ için gerekli)
    if (Platform.isAndroid) {
      try {
        // Android 12+ (API 31+) cihazlarda tam alarm izni istiyoruz
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
                
        if (androidPlugin != null) {
          print('Android plugin bulundu, tam alarm izni isteniyor...');
          final bool? hasExactAlarmPermission = 
              await androidPlugin.requestExactAlarmsPermission();
          print('Tam alarm izni sonucu: $hasExactAlarmPermission');
        } else {
          print('Android plugin bulunamadı, tam alarm izni istenemedi');
        }
      } catch (e) {
        print('Tam alarm izni istenirken hata: $e');
      }
    }
  }

  // Bildirim kaydını sil
  Future<void> _clearNotificationRecord() async {
    try {
      // Bugünün tarihini al
      final now = DateTime.now();
      String todayKey = 'notification_sent_${now.year}_${now.month}_${now.day}';
      
      // SharedPreferences üzerinden kaydı sil
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(todayKey);
      
      print('Bildirim kaydı silindi: $todayKey');
    } catch (e) {
      print('Bildirim kaydı silinirken hata: $e');
    }
  }

  // Bildirim ayarlarını veritabanından al
  Future<NotificationSettings?> getNotificationSettings() async {
    print('getNotificationSettings başlatıldı');
    final userId = await _authService.getUserId();
    if (userId == null) {
      print('getNotificationSettings: Kullanıcı ID bulunamadı');
      return null;
    }

    try {
      // Tüm ayarları al ve sırala (birden fazla kayıt olabilir)
      print('Kullanıcı ID: $userId için bildirim ayarları alınıyor');
      final results = await supabase
          .from('notification_settings')
          .select()
          .eq('user_id', userId)
          .order('id', ascending: false); // En son eklenen kayıtları önce al
      
      print('Bulunan ayar sayısı: ${results.length}');
      
      if (results.isNotEmpty) {
        // İlk kaydı (en son eklenen) kullan
        final latestSettings = results.first;
        print('En son ayarlar kullanılıyor: id=${latestSettings['id']}');
        return NotificationSettings.fromMap(latestSettings);
      } else {
        // Varsayılan ayarları oluşturmak yerine null döndür
        print('Ayar bulunamadı, null döndürülüyor');
        return null;
      }
    } catch (e, stack) {
      print('getNotificationSettings hatası: $e');
      logError('Bildirim ayarları alınırken hata', e, stack);
      return null;
    }
  }

  // Bildirim ayarlarını güncelle
  Future<bool> updateNotificationSettings(NotificationSettings settings) async {
    try {
      final now = DateTime.now();
      print('updateNotificationSettings başlatıldı: $settings');

      // Bildirim ayarlarını veritabanına kaydet
      final savedSettings = await _saveNotificationSettings(settings);

      if (savedSettings == null) {
        print('Bildirim ayarları kaydedilemedi');
        return false;
      }

      print('Bildirim ayarları kaydedildi, bildirim durumunu kontrol ediyorum');

      // Bugün için yevmiye girişi yapılmış mı kontrol et
      final hasAttendanceToday = await hasAttendanceEntryForToday();
      final localAttendanceDone = await AttendanceCheck.isTodayAttendanceDone();
      
      print('Yevmiye durumu kontrolü: hasAttendanceToday=$hasAttendanceToday, localAttendanceDone=$localAttendanceDone');

      // Bildirim zamanı hesapla
      final timeParts = settings.time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

      // Bildirim saati geçmiş mi kontrol et
      final isTimePassedForToday = scheduledTime.isBefore(now);
      print('Bildirim saati bugün için geçmiş mi? $isTimePassedForToday');

      // Eğer bugün için yevmiye girişi yapılmışsa, bildirimleri kapat
      if (hasAttendanceToday || localAttendanceDone) {
        // Tüm bildirimleri iptal et
        await flutterLocalNotificationsPlugin.cancelAll();
        print('Bugün için yevmiye girişi yapıldığından bildirimler iptal edildi');
        
        // Eğer bildirimler aktifse, kullanıcıya bilgi ver
        if (settings.enabled) {
          print('Bildirimler aktif, ancak bugün için yevmiye girişi yapıldığından bildirim gönderilmeyecek');
          await flutterLocalNotificationsPlugin.show(
            998,
            'Bildirim Ayarları Kaydedildi',
            'Bildirimler etkinleştirildi, ancak bugün için yevmiye girişi yapıldığı için bildirim gönderilmeyecek.',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'test_channel',
                'Test Bildirimleri',
                channelDescription: 'Test bildirimleri için kanal',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );
        } else {
          print('Bildirimler devre dışı bırakıldı');
        }
      } else if (settings.enabled) {
        // Bildirim zamanlamasını güncelle
        print('Bildirim zamanlaması güncelleniyor...');
        await _scheduleAttendanceReminder(settings);
        
        // Eğer ayarlanan saat bugün için geçtiyse ve yevmiye girişi yoksa
        if (scheduledTime.isBefore(now)) {
          print('Belirlenen saat (${settings.time}) geçtiği ve yevmiye girişi bulunmadığı için hemen kontrol yapılacak');
          await checkAttendanceAndNotifyIfNeeded();
        } else {
          // Belirlenen saat henüz gelmediyse, normal şekilde zamanlama yapılacak
          print('Belirlenen saat (${settings.time}) henüz gelmediği için normal bildirim zamanlaması yapıldı');
        }
      } else {
        print('Bildirimler devre dışı bırakıldı, zamanlama yapılmadı');
      }

      print('updateNotificationSettings başarıyla tamamlandı');
      return true;
    } catch (e, stack) {
      print('updateNotificationSettings hatası: $e');
      print('Stack trace: $stack');
      logError('Bildirim ayarları güncellenirken hata', e, stack);
      return false;
    }
  }

  // Yevmiye girişi yapılıp yapılmadığını kontrol et
  Future<bool> hasAttendanceEntryForToday() async {
    try {
      final today = DateTime.now();
      print('Bugün için yevmiye kontrolü yapılıyor: ${today.toIso8601String()}');
      
      // 1. AttendanceService ile veritabanından kayıtları kontrol et
      final attendanceRecords = await _attendanceService.getAttendanceByDate(today);
      print('Bugün için veritabanında bulunan kayıt sayısı: ${attendanceRecords.length}');
      
      // 2. Kullanıcıya özel yerel kayıtları kontrol et (AttendanceCheck)
      final localAttendanceDone = await AttendanceCheck.isTodayAttendanceDone();
      print('Kullanıcıya özel yevmiye durumu kontrolü: $localAttendanceDone');
      
      // 3. SharedPreferences'dan ek kontroller
      final prefs = await SharedPreferences.getInstance();
      
      // 3.1. notification_sent kontrolü
      String todayKey = 'notification_sent_${today.year}_${today.month}_${today.day}';
      bool notificationSentToday = prefs.getBool(todayKey) ?? false;
      print('SharedPreferences\'dan bildirim gönderilme durumu kontrolü ($todayKey): $notificationSentToday');
      
      // Herhangi bir kayıt varsa, bildirimi gönderildi olarak işaretle
      final hasAnyRecord = attendanceRecords.isNotEmpty || localAttendanceDone;
      
      if (hasAnyRecord) {
        // Bildirim gönderildiğine dair kaydı güncelle
        await prefs.setBool(todayKey, true);
        print('Yevmiye girişi bulunduğu için bildirim durumu işaretlendi: $todayKey = true');
        
        // Eğer zaten bildirim gönderilmişse ve yevmiye kaydı varsa, o zaman bildirim kaydını sil
        await _clearNotificationRecord();
        
        // Bekleyen bildirimleri de temizle
        await flutterLocalNotificationsPlugin.cancelAll();
        print('Bekleyen bildirimler temizlendi');
        
        // Yevmiye durumunu kullanıcıya özel olarak işaretle
        await AttendanceCheck.markAttendanceDone();
        print('Yevmiye durumu kullanıcıya özel olarak işaretlendi');
      }
      
      return hasAnyRecord;
    } catch (e) {
      print('Yevmiye kontrolü yapılırken hata: $e');
      return false;
    }
  }

  // Yevmiye hatırlatıcısını zamanla
  Future<void> _scheduleAttendanceReminder(NotificationSettings settings) async {
    try {
      print('Yevmiye hatırlatıcısı zamanlanıyor: ${settings.time}');

      // Kullanıcı bilgilerini al
      final userData = await _authService.currentUser;
      if (userData == null) {
        print('Kullanıcı bilgisi olmadan bildirim zamanlanamaz');
      return;
    }

      final userId = userData['id'] as int;
      final username = userData['username'] as String;
      final firstName = userData['first_name'] as String;
      final lastName = userData['last_name'] as String;
      final fullName = '$firstName $lastName';

      // Bildirim içeriğini kullanıcı bilgisiyle zenginleştir
      final String title = 'Yevmiye Hatırlatıcısı - $fullName';
      final String body = 'Bugünkü yevmiye kayıtlarını girmeyi unutmayın.';
      
      // Payload oluştur
      final payload = NotificationPayload(
        type: 'attendance_reminder',
        userId: userId,
        username: username,
        fullName: fullName,
      );

      // Bildirim zamanını hesapla
      final now = DateTime.now();
      final timeParts = settings.time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      // Bugün için zaman hesapla
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
      
      // Eğer belirtilen saat geçtiyse, yarın için planla
      if (scheduledDate.isBefore(now)) {
        print('Belirtilen saat bugün için geçmiş, yarına planlanıyor');
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      // Bildirimi zamanla
      await flutterLocalNotificationsPlugin.zonedSchedule(
        1, // Yevmiye bildirimi için sabit ID
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
          'attendance_reminder',
          'Yevmiye Hatırlatıcısı',
          channelDescription: 'Günlük yevmiye girişi hatırlatıcısı',
          importance: Importance.max,
            priority: Priority.high,
            color: const Color(0xFF2196F3),
          ),
          iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload.toJsonString(),
      );

      print('Yevmiye hatırlatıcısı başarıyla zamanlandı: ${scheduledDate.toString()}');
    } catch (e, stack) {
      print('Yevmiye hatırlatıcısı zamanlanırken hata: $e');
      logError('Yevmiye hatırlatıcısı zamanlanırken hata', e, stack);
    }
  }

  // Uygulama açıldığında bildirimleri kontrol et ve yeniden zamanla
  Future<void> checkAndRescheduleNotifications() async {
    try {
      print('Bildirim ayarları kontrol ediliyor...');
      
      // Önce AttendanceCheck ile yevmiye girişi yapılmış mı kontrol et
      final isDoneLocally = await AttendanceCheck.isTodayAttendanceDone();
      if (isDoneLocally) {
        print('AttendanceCheck kontrolünde bugün için yevmiye girişi bulundu, bildirimler temizleniyor.');
        await flutterLocalNotificationsPlugin.cancelAll();
        
        // Bugün için bildirimi gönderildi olarak işaretle
        final now = DateTime.now();
        String todayKey = 'notification_sent_${now.year}_${now.month}_${now.day}';
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool(todayKey, true);
        
        print('Bildirim durumu işaretlendi (checkAndRescheduleNotifications): $todayKey = true');
      }
      
      // Önce mevcut zamanlanmış bildirimleri kontrol et
      final pendingNotifications = await getPendingNotifications();
      print('Mevcut zamanlanmış bildirim sayısı: ${pendingNotifications.length}');
      
      // Bildirimden başlatılma durumunu kontrol et
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool launchedFromNotification = prefs.getBool('launched_from_notification') ?? false;
      
      // Eğer uygulama bildirimden başlatıldıysa, tüm bildirimleri temizle ve yeniden zamanlamayı atla
      if (launchedFromNotification) {
        print('Uygulama bildirimden başlatılmış, bildirimler temizleniyor ve yeni zamanlanmıyor.');
        await flutterLocalNotificationsPlugin.cancelAll();
        
        // Bugün için bildirimi gönderildi olarak işaretle
        final now = DateTime.now();
        String todayKey = 'notification_sent_${now.year}_${now.month}_${now.day}';
        await prefs.setBool(todayKey, true);
        
        return;
      }
      
      // Ayarlar yoksa veya özellik kapalıysa bildirimleri iptal et
      final settings = await getNotificationSettings();
      
      if (settings == null) {
        print('Bildirim ayarları bulunamadı, tüm bildirimler iptal ediliyor');
        // Ayarlar yoksa tüm bildirimleri iptal et
        await flutterLocalNotificationsPlugin.cancelAll();
      } else {
      print('Bildirim ayarları bulundu: enabled=${settings.enabled}, time=${settings.time}');
      
      if (settings.enabled) {
        print('Bildirimler etkin, kontrol ediliyor...');
        
        // Bugün için bildirim gönderilip gönderilmediğini kontrol et
        final now = DateTime.now();
        String todayKey = 'notification_sent_${now.year}_${now.month}_${now.day}';
        bool notificationSentToday = prefs.getBool(todayKey) ?? false;
        
        if (notificationSentToday) {
          print('Bugün için bildirim zaten gönderilmiş, tekrar zamanlanmayacak.');
            // Ancak yevmiye bildirimleri için geçerli - çalışan hatırlatıcıları hala gösterilmeli
        }
        
        // Eğer zamanlanmış bildirim yoksa, yeniden zamanla
        if (pendingNotifications.isEmpty) {
          print('Zamanlanmış bildirim bulunamadı, yeniden zamanlanıyor...');
            
            // 1. Yevmiye hatırlatıcısını zamanla
          await _scheduleAttendanceReminder(settings);
            
            // 2. Çalışan hatırlatıcılarını yeniden zamanla
            await _rescheduleEmployeeReminders();
        } else {
          print('Zamanlanmış bildirimler zaten mevcut, yeniden zamanlamaya gerek yok');
        }
        
        // Bugün için zamanı kontrol et
        print('Şu anki saat: ${now.toString()}');
        
        final timeParts = settings.time.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
        
        print('Ayarlanan bildirim saati: ${scheduledTime.toString()}');
        print('Şu anki saat ile karşılaştırma: ${now.isAfter(scheduledTime) ? "Geçmiş" : "Gelecek"}');
        
        // Eğer bildirim saati geçtiyse, henüz yevmiye girişi yapılmamışsa VE bugün bildirim gönderilmediyse
        if (now.isAfter(scheduledTime) && !notificationSentToday) {
          print('Bildirim saati geçmiş (${settings.time}) ve bugün bildirim gönderilmemiş, yevmiye kontrolü yapılıyor...');
          final hasAttendance = await hasAttendanceEntryForToday();
          if (!hasAttendance) {
            // Yerel depolamadan da kontrol et
            final isDoneLocally = await AttendanceCheck.isTodayAttendanceDone();
            if (isDoneLocally) {
              print('AttendanceCheck üzerinde yevmiye girişi bulundu, bildirim gönderilmeyecek.');
              await prefs.setBool(todayKey, true);
            } else {
              print('Bugün için yevmiye girişi bulunamadı, bildirim gönderiliyor...');
              await checkAttendanceAndNotifyIfNeeded();
            }
          } else {
            print('Bugün için yevmiye girişi zaten yapılmış, bildirim gönderilmiyor.');
            // Yevmiye girişi yapılmış olsa da bildirim gönderildi olarak işaretle
            await prefs.setBool(todayKey, true);
          }
        } else if (now.isAfter(scheduledTime) && notificationSentToday) {
          print('Bildirim saati geçmiş (${settings.time}) ama bugün için bildirim zaten gönderilmiş, tekrar gönderilmeyecek.');
        } else {
          print('Bildirim saati (${settings.time}) henüz gelmedi, zamanlanmış bildirim beklenecek.');
        }
      } else {
        print('Bildirimler devre dışı, tüm bildirimler iptal ediliyor');
          // Bildirimlerin devre dışı olması yevmiye bildirimleri için geçerli, çalışan hatırlatıcıları yine de gösterilmeli
          
          // Tüm YEVMIYE bildirimlerini iptal et
          await flutterLocalNotificationsPlugin.cancel(1); // Yevmiye bildirimi ID'si
          
          // Çalışan hatırlatıcılarını kontrol et ve gerekirse yeniden zamanla
          await _rescheduleEmployeeReminders();
      }
      }
      
      // Her durumda çalışan hatırlatıcılarını kontrol et ve güncelle
      await _rescheduleEmployeeReminders();
    } catch (e, stack) {
      print('Bildirimler kontrol edilirken hata: $e');
      logError('Bildirimler kontrol edilirken hata', e, stack);
    }
  }
  
  // Çalışan hatırlatıcılarını yeniden zamanla
  Future<void> _rescheduleEmployeeReminders() async {
    try {
      debugPrint('Çalışan hatırlatıcıları yeniden zamanlanıyor...');
      
      // Mevcut kullanıcı ID'sini al - sadece loglama için
      final currentUserId = await _authService.getUserId();
      if (currentUserId == null) {
        debugPrint('Kullanıcı oturumu bulunamadı, ancak tüm hatırlatıcıları kontrol edeceğiz');
      } else {
        debugPrint('Mevcut kullanıcı ID: $currentUserId');
      }
      
      // Gelecek tarihli ve tamamlanmamış TÜM hatırlatıcıları al
      // NOT: user_id filtresini kaldırdık - tüm kullanıcıların hatırlatıcılarını alıyoruz
      final now = DateTime.now();
      final nowStr = now.toIso8601String();
      
      final List<dynamic> reminders = await supabase
          .from('employee_reminders')
          .select()
          .eq('is_completed', 0)
          .gte('reminder_date', nowStr)
          .order('reminder_date', ascending: true);
      
      debugPrint('Zamanlanacak çalışan hatırlatıcısı sayısı: ${reminders.length}');
      
      if (reminders.isEmpty) {
        debugPrint('Zamanlanacak çalışan hatırlatıcısı bulunamadı');
        return;
      }
      
      // Her hatırlatıcıyı zamanla
      for (final reminderData in reminders) {
        try {
          await scheduleEmployeeReminderNotification(reminderData);
          // İşlemlerin üst üste binmemesi için kısa bir bekleme
          await Future.delayed(const Duration(milliseconds: 50));
        } catch (e) {
          debugPrint('Hatırlatıcı zamanlanırken hata: $e');
          // Tek bir hatırlatıcıda hata olsa bile diğerlerine devam et
          continue;
        }
      }
      
      debugPrint('Çalışan hatırlatıcıları başarıyla yeniden zamanlandı: ${reminders.length} adet');
    } catch (e) {
      debugPrint('Çalışan hatırlatıcıları yeniden zamanlanırken hata: $e');
    }
  }

  // Yevmiye girişi kontrolü yap ve gerekirse bildirim gönder
  Future<void> checkAttendanceAndNotifyIfNeeded() async {
    try {
      print('Yevmiye kontrolü başlatılıyor...');
      
      // Bugün için bildirim gönderilip gönderilmediğini kontrol et
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      String todayKey = 'notification_sent_${now.year}_${now.month}_${now.day}';
      bool notificationSentToday = prefs.getBool(todayKey) ?? false;
      
      if (notificationSentToday) {
        print('Bugün için bildirim zaten gönderilmiş, tekrar gönderilmeyecek.');
        return;
      }
      
      // Daha önce zamanlanmış ve bekleyen bildirimleri kontrol et
      final pendingNotifications = await getPendingNotifications();
      if (pendingNotifications.isNotEmpty) {
        print('Zaten zamanlanmış ${pendingNotifications.length} bildirim var, yeni bildirim gönderilmeyecek.');
        return;
      }
      
      // Bugün için yevmiye girişi var mı kontrol et
      final hasAttendance = await hasAttendanceEntryForToday();
      
      // Eğer yevmiye girişi yoksa bildirim gönder
      if (!hasAttendance) {
        print('Yevmiye girişi bulunamadı, bildirim gönderiliyor...');
        
        // Ayrıca AttendanceCheck'i de kontrol et (fazladan güvenlik)
        final isDoneLocally = await AttendanceCheck.isTodayAttendanceDone();
        if (isDoneLocally) {
          print('AttendanceCheck üzerinde yevmiye girişi bulundu, bildirim gönderilmeyecek.');
          await prefs.setBool(todayKey, true);
          
          // Uygulama yeniden başlatıldığında kullanılacak değerleri güncelle
          await prefs.setBool('attendance_done_today', true);
          await prefs.setString('attendance_date', now.toIso8601String());
          return;
        }
        
        // Android'de intent tanımla
        String notificationPayload = 'attendance_reminder';
        
        // Platform'a özgü bildirim yapılandırması
        NotificationDetails platformChannelSpecifics;
        
        if (Platform.isAndroid) {
          // Android platformu için
          final androidDetails = AndroidNotificationDetails(
            'attendance_reminder_immediate',
            'Yevmiye Hatırlatıcısı',
            channelDescription: 'Günlük yevmiye girişi hatırlatıcısı',
            importance: Importance.high,
            priority: Priority.high,
            autoCancel: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.reminder,
            visibility: NotificationVisibility.public,
            icon: '@mipmap/launcher_icon',
          );
          
          platformChannelSpecifics = NotificationDetails(android: androidDetails);
        } else {
          // iOS platformu için
          final iOSDetails = const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          );
          
          platformChannelSpecifics = NotificationDetails(iOS: iOSDetails);
        }
        
        // Bildirimi göster
        await flutterLocalNotificationsPlugin.show(
          1,
          'Yevmiye Hatırlatıcısı',
          'Bugün çalışanların yevmiye girişi yapılmadı. Kontrol etmek için dokunun.',
          platformChannelSpecifics,
          payload: notificationPayload,
        );
        
        print('Yevmiye hatırlatıcısı bildirimi gönderildi (yevmiye girişi yok)');
        
        // Bildirimin bugün gönderildiğini kaydet
        await prefs.setBool(todayKey, true);
        
        // Uygulamanın bildirime tıklama ile açılmasını sağlamak için işaret bırak
        await prefs.setString('last_notification_payload', notificationPayload);
        await prefs.setBool('notification_needs_handling', true);
        
        // flutter. öneki SharedPreferences'ın Flutter ve native tarafta erişilebilir olmasını sağlar
        await prefs.setBool('flutter.notification_needs_handling', true);
      } else {
        print('Yevmiye girişi zaten yapılmış, bildirim gönderilmedi');
        // Yevmiye girişi yapılmış olsa da bildirim gönderildi olarak işaretle
        await prefs.setBool(todayKey, true);
      }
    } catch (e, stack) {
      print('Yevmiye kontrolü yapılırken hata: $e');
      logError('Yevmiye kontrolü yapılırken hata', e, stack);
    }
  }

  // Test bildirimi gönder
  Future<void> sendTestNotification() async {
    try {
      final now = DateTime.now();
      
      // Normal bildirim kanalı testi
      await flutterLocalNotificationsPlugin.show(
        9999,
        'Test Bildirimi',
        'Bu bir test bildirimidir. Şu an: ${now.toString()}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Bildirimleri',
            channelDescription: 'Test bildirimleri için kanal',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'test_notification',
      );
      
      print('Test bildirimi gönderildi');
      
      // Mevcut zamanlanmış bildirimleri kontrol et
      final pendingNotifications = await getPendingNotifications();
      print('Toplam ${pendingNotifications.length} adet zamanlanmış bildirim var');
    } catch (e) {
      print('Test bildirimi gönderilirken hata: $e');
    }
  }

  // Kullanıcı ID'sini döndürür
  Future<int?> getCurrentUserId() async {
    return await _authService.getUserId();
  }

  // Zamanlanmış bildirimleri kontrol et
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pendingNotifications = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      print('Zamanlanmış bildirim sayısı: ${pendingNotifications.length}');
      
      for (var notification in pendingNotifications) {
        print('Bildirim ID: ${notification.id}, Başlık: ${notification.title}, İçerik: ${notification.body}');
      }
      
      return pendingNotifications;
    } catch (e, stack) {
      print('Zamanlanmış bildirimler kontrol edilirken hata: $e');
      logError('Zamanlanmış bildirimler kontrol edilirken hata', e, stack);
      return [];
    }
  }

  // Tüm bildirimleri temizle
  Future<void> clearAllNotifications() async {
    try {
      // Tüm bildirimleri iptal et
      await flutterLocalNotificationsPlugin.cancelAll();
      print('Tüm bildirimler temizlendi');
      
      // Bugünün bildirim kaydını da temizle
      await _clearNotificationRecord();
      
      // Bildirimden başlatılma durumunu da temizle
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('launched_from_notification', false);
      await prefs.remove('last_notification_payload');
      await prefs.setBool('notification_needs_handling', false);
      await prefs.setBool('flutter.notification_needs_handling', false);
      
      // Bugün için yevmiye kontrolü yapıldı olarak işaretle
      final now = DateTime.now();
      String todayKey = 'notification_sent_${now.year}_${now.month}_${now.day}';
      await prefs.setBool(todayKey, true);
      print('Bugün için bildirim durumu işaretlendi: $todayKey = true');
    } catch (e) {
      print('Bildirimler temizlenirken hata: $e');
    }
  }

  // Bildirimden başlatılma durumunu kontrol et
  Future<void> checkLaunchedFromNotification() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool launchedFromNotification = prefs.getBool('launched_from_notification') ?? false;
      
      if (launchedFromNotification) {
        // Önce tüm bildirimleri temizle
        await flutterLocalNotificationsPlugin.cancelAll();
        print('Tüm bildirimler temizlendi');
        
        // Bugünün bildirim kaydını temizle (bugün için artık bildirim gönderilmemesi için)
        await _clearNotificationRecord();
        
        String? payload = prefs.getString('last_notification_payload');
        print('Uygulama bildirimden başlatıldı, payload: $payload');
        
        if (payload != null) {
          // Bildirimi işle
          _handleNotificationPayload(payload);
          
          // Bildirim işlendikten sonra temizle
          await prefs.setBool('launched_from_notification', false);
          await prefs.remove('last_notification_payload');
          
          // Bugün için yevmiye kontrolü yapıldı olarak işaretle
          final now = DateTime.now();
          String todayKey = 'notification_sent_${now.year}_${now.month}_${now.day}';
          await prefs.setBool(todayKey, true);
          print('Bugün için bildirim durumu işaretlendi: $todayKey = true');
        }
      } else {
        print('Uygulama normal şekilde başlatıldı');
      }
    } catch (e) {
      print('Bildirimden başlatılma durumu kontrolü hatası: $e');
    }
  }

  // Bildirim ayarlarını veritabanına kaydet
  Future<NotificationSettings?> _saveNotificationSettings(NotificationSettings settings) async {
    try {
      print('Kullanıcının mevcut tüm ayarları temizleniyor (userId: ${settings.userId})');
      await supabase
          .from('notification_settings')
          .delete()
          .eq('user_id', settings.userId);
      
      // Sonra yeni ayarları ekle
      print('Yeni ayar ekleniyor');
      final insertMap = settings.toMap();
      print('Gönderilen veri: $insertMap');
      
      final response = await supabase
          .from('notification_settings')
          .insert(insertMap)
          .select();
      
      print('Ayar eklendi, yanıt: $response');
      
      if (response.isNotEmpty) {
        return NotificationSettings.fromMap(response[0]);
      }
      return null;
    } catch (e, stack) {
      print('Bildirim ayarları kaydedilirken hata: $e');
      print('Stack trace: $stack');
      return null;
    }
  }

  // Belirli bir bildirimi iptal et
  Future<void> cancelNotification(int? id) async {
    try {
      if (id == null) {
        debugPrint('Bildirim ID null, iptal edilemedi');
        return;
      }
      await flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('Bildirim iptal edildi: $id');
    } catch (e) {
      debugPrint('Bildirim iptal edilirken hata: $e');
    }
  }
  
  // Belirli bir tarih ve saatte bildirim zamanla
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      // Önce izinleri kontrol et
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        debugPrint('Bildirim izni yok, bildirim zamanlanamadı');
        return;
      }
      
      // Şimdiki zamanı al
      final now = DateTime.now();
      
      // Öncelikle tarihin güncel olup olmadığını kontrol et
      // Eğer tarih 1 aydan daha uzaktaysa muhtemelen bir UTC dönüşüm hatası var
      if (scheduledDate.difference(now).inDays > 30) {
        debugPrint('UYARI: Çok uzak bir tarih tespit edildi: ${scheduledDate.toString()}');
        debugPrint('Bu muhtemelen bir UTC dönüşüm hatası. Tarihi düzeltiyorum.');
        
        // Güncel tarih ve saat bilgilerini kullan (aynı gün ve şu andan 2 dakika sonra)
        final correctedDate = now.add(const Duration(minutes: 2));
        scheduledDate = DateTime(
          correctedDate.year,
          correctedDate.month,
          correctedDate.day,
          correctedDate.hour,
          correctedDate.minute
        );
        debugPrint('Düzeltilmiş tarih: ${scheduledDate.toString()}');
      }
      
      // Eğer belirtilen saat geçtiyse, bildirimi 2 dakika sonraya zamanla
      final effectiveDate = scheduledDate.isBefore(now)
          ? now.add(const Duration(minutes: 2))
          : scheduledDate;
      
      // Zamanlama için TZDateTime oluştur
      tz.initializeTimeZones(); // Her ihtimale karşı initialize et
      final tz.Location location = tz.getLocation('Europe/Istanbul');
      debugPrint('Kullanılan saat dilimi: ${location.name}');
      
      // Doğrudan TZDateTime oluştur (DateTime.from kullanmadan)
      final tz.TZDateTime tzScheduledDate = tz.TZDateTime(
        location,
        effectiveDate.year,
        effectiveDate.month,
        effectiveDate.day,
        effectiveDate.hour,
        effectiveDate.minute,
        effectiveDate.second
      );
      
      debugPrint('Bildirim zamanlanıyor (yerel saat): ${effectiveDate.toString()}');
      debugPrint('Bildirim zamanlanıyor (TZ): ${tzScheduledDate.toString()}');
      
      // Android için bildirim detayları
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'employee_reminders',
        'Çalışan Hatırlatıcıları',
        channelDescription: 'Çalışanlar için özel hatırlatıcılar',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        channelAction: AndroidNotificationChannelAction.createIfNotExists,
      );
      
      // iOS için bildirim detayları
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      );
      
      // Genel bildirim detayları
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Önce mevcut bildirimi iptal et (varsa)
      await flutterLocalNotificationsPlugin.cancel(id);
      
      // Bildirimi zamanla
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      
      debugPrint('Bildirim başarıyla zamanlandı: ID=$id, Tarih=$tzScheduledDate, Payload=$payload');
      
      // Android'de bildirim izinlerini kontrol et
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
                
        if (androidPlugin != null) {
          final bool? areNotificationsEnabled = await androidPlugin.areNotificationsEnabled();
          debugPrint('Android bildirim izinleri: $areNotificationsEnabled');
          
          // İzin yoksa iste
          if (areNotificationsEnabled == false) {
            await androidPlugin.requestNotificationsPermission();
            debugPrint('Android bildirim izinleri istendi');
          }
          
          // Android 13+ için bildirim izinlerini iste (opsiyonel olarak)
          try {
            // Alternatif izin yöntemi: Permission handler kullan
            final permissionStatus = await Permission.notification.request();
            debugPrint('Android notification izin durumu: $permissionStatus');
          } catch (e) {
            // Hata durumunda
            debugPrint('Android bildirim izinleri istenemedi: $e');
          }
        }
      }
      
    } catch (e, stack) {
      debugPrint('Bildirim zamanlanırken hata: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  // Çalışan hatırlatıcısı için bildirim gönder
  Future<bool> scheduleEmployeeReminderNotification(Map<String, dynamic> reminderData) async {
    try {
      final int reminderId = reminderData['id'];
      final String workerName = reminderData['worker_name'];
      final String message = reminderData['message'];
      final DateTime reminderDate = DateTime.parse(reminderData['reminder_date']);
      final int userId = reminderData['user_id'];
      
      debugPrint('Çalışan hatırlatıcısı bildirimi ayarlanıyor:');
      debugPrint('ID: $reminderId');
      debugPrint('Çalışan: $workerName');
      debugPrint('Mesaj: $message');
      debugPrint('Veritabanı Tarihi: $reminderDate');
      debugPrint('Kullanıcı ID: $userId');
      
      // Supabase'den gelen UTC tarihini yerel saat dilimine çevir
      final localReminderDate = reminderDate.isUtc ? reminderDate.toLocal() : reminderDate;
      debugPrint('Yerel saat dilimine çevrilmiş tarih: $localReminderDate');
      
      // Android izinlerini kontrol et
      await _checkAndRequestNotificationPermissions();
      
      // Kullanıcı bilgilerini alalım - bildirimin kullanıcıdan bağımsız gösterilmesi için
      String username = "kullanıcı";
      String fullName = "Puantaj Kullanıcısı";
      
      try {
        final userData = await supabase
            .from('users')
            .select('username, first_name, last_name')
            .eq('id', userId)
            .single();
            
        if (userData != null) {
          username = userData['username'] as String;
          final firstName = userData['first_name'] as String? ?? '';
          final lastName = userData['last_name'] as String? ?? '';
          fullName = '$firstName $lastName'.trim();
          if (fullName.isEmpty) fullName = username;
        }
        
        debugPrint('Bildirim için kullanıcı bilgileri bulundu: $username ($fullName)');
      } catch (e) {
        debugPrint('Kullanıcı bilgileri alınırken hata: $e');
        // Varsayılan değerleri kullan
      }
      
      // Bildirim içeriği
      final String title = 'Çalışan Hatırlatıcısı - $workerName (${fullName})';
      final String body = message;
      
      // Şimdiki zamanı al
      final now = DateTime.now();
      
      // Bildirimin zamanını kontrol et
      if (localReminderDate.isBefore(now)) {
        debugPrint('Hatırlatıcı tarihi geçmiş, bildirim gönderilmiyor: $localReminderDate');
        return false;
      }
      
      // Önce bildirimleri iptal et (varsa) - aynı ID'ye sahip bildirimler çakışmasın
      await flutterLocalNotificationsPlugin.cancel(reminderId);
      debugPrint('Önceki aynı ID bildirimler iptal edildi: $reminderId');
      
      // Bildirim payload'ı (kullanıcı bilgileriyle)
      final payload = NotificationPayload(
        type: 'employee_reminder',
        userId: userId,
        username: username,
        fullName: fullName,
        reminderId: reminderId,
      ).toJsonString();
      
      // Öncelikle tarihin güncel olup olmadığını kontrol et
      // Eğer tarih 1 aydan daha uzaktaysa muhtemelen bir UTC dönüşüm hatası var
      DateTime effectiveDate = localReminderDate;
      if (localReminderDate.difference(now).inDays > 30) {
        debugPrint('UYARI: Çok uzak bir tarih tespit edildi: ${localReminderDate.toString()}');
        debugPrint('Bu muhtemelen bir UTC dönüşüm hatası. Tarihi düzeltiyorum.');
        
        // Güncel tarih ve saat bilgilerini kullan (aynı gün ve şu andan 2 dakika sonra)
        final correctedDate = now.add(const Duration(minutes: 2));
        effectiveDate = DateTime(
          correctedDate.year,
          correctedDate.month,
          correctedDate.day,
          correctedDate.hour,
          correctedDate.minute
        );
        debugPrint('Düzeltilmiş tarih: ${effectiveDate.toString()}');
      }
      
      // Eğer belirtilen saat geçtiyse, bildirimi 2 dakika sonraya zamanla
      if (effectiveDate.isBefore(now)) {
        effectiveDate = now.add(const Duration(minutes: 2));
        debugPrint('Geçmiş tarih düzeltildi: ${effectiveDate.toString()}');
      }
      
      // Zamanlama için TZDateTime oluştur
      tz.initializeTimeZones(); // Her ihtimale karşı initialize et
      final tz.Location location = tz.getLocation('Europe/Istanbul');
      debugPrint('Kullanılan saat dilimi: ${location.name}');
      
      // Doğrudan TZDateTime oluştur
      final tz.TZDateTime tzScheduledDate = tz.TZDateTime(
        location,
        effectiveDate.year,
        effectiveDate.month,
        effectiveDate.day,
        effectiveDate.hour,
        effectiveDate.minute,
        effectiveDate.second
      );
      
      debugPrint('Bildirim zamanlanıyor (yerel saat): ${effectiveDate.toString()}');
      debugPrint('Bildirim zamanlanıyor (TZ): ${tzScheduledDate.toString()}');
      
      // Android için bildirim detayları
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'employee_reminders',
        'Çalışan Hatırlatıcıları',
        channelDescription: 'Çalışanlar için özel hatırlatıcılar',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        channelAction: AndroidNotificationChannelAction.createIfNotExists,
      );
      
      // iOS için bildirim detayları
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      );
      
      // Genel bildirim detayları
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      try {
        // Bildirimi zamanla - matchDateTimeComponents ekledik
        await flutterLocalNotificationsPlugin.zonedSchedule(
          reminderId, // Benzersiz ID
          title,
          body,
          tzScheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
          matchDateTimeComponents: DateTimeComponents.time, // Hesaplar arası çalışması için önemli
        );
        
        // Bildirim zamanlandığını göstermek için dosyaya kaydet
        await _saveReminderNotificationRecord(reminderId, userId, tzScheduledDate);
        
        debugPrint('Çalışan hatırlatıcısı bildirimi zamanlandı: ID=$reminderId, Tarih=$tzScheduledDate');
        return true;
      } catch (e) {
        debugPrint('Çalışan hatırlatıcısı bildirimi zamanlanırken hata: $e');
        
        // Hata durumunda manuel yöntem dene
        try {
          // Alternatif yöntem: doğrudan zonedSchedule kullan
          await flutterLocalNotificationsPlugin.zonedSchedule(
            reminderId,
            title,
            body,
            tzScheduledDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: payload,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          
          debugPrint('Alternatif yöntemle bildirim zamanlandı: ID=$reminderId');
          return true;
        } catch (e2) {
          debugPrint('Alternatif yöntem de başarısız: $e2');
          return false;
        }
      }
    } catch (e) {
      debugPrint('Çalışan hatırlatıcısı bildirimi işlenirken hata: $e');
      return false;
    }
  }
  
  // Zamanlanmış bildirim kaydını dosyaya kaydet
  Future<void> _saveReminderNotificationRecord(int reminderId, int userId, tz.TZDateTime scheduledDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'employee_reminder_${reminderId}_${userId}';
      
      // Bildirim kaydını JSON formatında sakla
      final notificationData = {
        'reminder_id': reminderId,
        'user_id': userId,
        'scheduled_date': scheduledDate.toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // JSON verisini kaydet
      await prefs.setString(key, jsonEncode(notificationData));
      
      // Ayrıca bu kullanıcı için tüm bildirimlerin listesini güncelle
      final userRemindersKey = 'user_reminders_$userId';
      final existingRemindersJson = prefs.getStringList(userRemindersKey) ?? [];
      
      // Mevcut ID'yi kontrol et
      final reminderIdStr = reminderId.toString();
      if (!existingRemindersJson.contains(reminderIdStr)) {
        existingRemindersJson.add(reminderIdStr);
        await prefs.setStringList(userRemindersKey, existingRemindersJson);
      }
      
      debugPrint('Hatırlatıcı bildirimi kaydedildi: $key, Tarih: ${scheduledDate.toString()}');
    } catch (e) {
      debugPrint('Hatırlatıcı bildirimi kaydedilirken hata: $e');
    }
  }

  // Bildirim izinlerini kontrol et ve gerekirse iste
  Future<void> _checkAndRequestNotificationPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Android için bildirim izinlerini kontrol et
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          // Bildirim izinlerini kontrol et
          final bool? areNotificationsEnabled = await androidPlugin.areNotificationsEnabled();
          debugPrint('Android bildirim izinleri: $areNotificationsEnabled');
          
          // İzin yoksa iste
          if (areNotificationsEnabled == false) {
            await androidPlugin.requestNotificationsPermission();
            debugPrint('Android bildirim izinleri istendi');
          }
          
          // Android 13+ için bildirim izinlerini iste (opsiyonel olarak)
          try {
            // Alternatif izin yöntemi: Permission handler kullan
            final permissionStatus = await Permission.notification.request();
            debugPrint('Android notification izin durumu: $permissionStatus');
          } catch (e) {
            // Hata durumunda
            debugPrint('Android bildirim izinleri istenemedi: $e');
          }
        }
      }
      
      // iOS için bildirim izinlerini kontrol et
      if (Platform.isIOS) {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          final result = await Permission.notification.request();
          debugPrint('iOS bildirim izni istendi, sonuç: $result');
        } else {
          debugPrint('iOS bildirim izni zaten verilmiş');
        }
      }
    } catch (e) {
      debugPrint('Bildirim izinleri kontrol edilirken hata: $e');
    }
  }
  
  // Bildirim izni uyarısı göster
  void _showNotificationPermissionWarning() {
    try {
      flutterLocalNotificationsPlugin.show(
        9999,
        'Bildirim İzni Gerekiyor',
        'Çalışan hatırlatıcıları için telefonunuzun "Ayarlar > Uygulamalar > Puantaj > Bildirimler" menüsünden tam izinleri vermeniz gerekiyor.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'permission_channel',
            'İzin Bildirimleri',
            channelDescription: 'İzin gerektiren durumlar için bildirimler',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        )
      );
    } catch (e) {
      debugPrint('İzin uyarısı gösterilirken hata: $e');
    }
  }

  // UTC tarihi yerel saat dilimine çevir
  DateTime _convertUtcToLocalTime(DateTime utcDate) {
    // Eğer tarih zaten yerel saat dilimindeyse, doğrudan döndür
    if (!utcDate.isUtc) {
      debugPrint('Tarih zaten yerel saat diliminde, dönüşüm yapılmadı');
      return utcDate;
    }
    
    // UTC tarihini yerel saat dilimine çevir
    final localDate = utcDate.toLocal();
    debugPrint('UTC tarih: $utcDate -> Yerel tarih: $localDate (Fark: ${localDate.difference(utcDate).inHours} saat)');
    return localDate;
  }
} 