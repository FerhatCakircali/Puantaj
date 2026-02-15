import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// import 'package:puantaj/core/app_router.dart'; // Artık kullanmıyoruz
import 'package:puantaj/services/auth_service.dart';
import 'package:puantaj/services/background_service.dart';
import 'package:puantaj/services/enhanced_background_service.dart' as enhanced;
import 'package:puantaj/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puantaj/core/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:puantaj/core/user_data_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:puantaj/screens/home_screen.dart';
import 'package:puantaj/screens/login_screen.dart';
import 'package:puantaj/screens/register_screen.dart';
import 'package:puantaj/screens/report_screen.dart';
import 'package:puantaj/screens/admin_panel_screen.dart';
import 'package:puantaj/screens/notification_settings_screen.dart';
import 'package:puantaj/screens/employee_reminder_detail_screen.dart';
import 'package:puantaj/screens/notification_test_screen.dart';
import 'package:puantaj/services/employee_reminder_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

// Uygulama yaşam döngüsü olaylarını izlemek için yardımcı sınıf
class LifecycleEventHandler extends WidgetsBindingObserver {
  final AsyncCallback? resumeCallBack;
  final AsyncCallback? suspendingCallBack;

  LifecycleEventHandler({this.resumeCallBack, this.suspendingCallBack});

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        if (resumeCallBack != null) {
          await resumeCallBack!();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        if (suspendingCallBack != null) {
          await suspendingCallBack!();
        }
        break;
    }
  }
}

// Hata yakalama için global handler
void logError(String message, dynamic error, StackTrace? stackTrace) {
  print('=== HATA BAŞLANGICI ===');
  print('MESAJ: $message');
  print('HATA: $error');
  if (stackTrace != null) {
    print('STACK TRACE: $stackTrace');
  }
  print('=== HATA SONU ===');
}

// Auth durumunu tutan global değişken
final ValueNotifier<bool> authStateNotifier = ValueNotifier<bool>(false);
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
  ThemeMode.system,
);

// Hesap değişim durumunu takip etmek için global değişken
bool isSwitchingAccounts = false;

// Hesap listesinin güncellenmesini bildirmek için global değişken
final ValueNotifier<bool> accountsUpdateNotifier = ValueNotifier<bool>(false);

// Supabase istemcisine global erişim
late final SupabaseClient supabase;

Future<ThemeMode> _getSavedThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final mode = prefs.getString('theme_mode');
  switch (mode) {
    case 'dark':
      return ThemeMode.dark;
    case 'light':
      return ThemeMode.light;
    case 'system':
      return ThemeMode.system;
    default:
      return ThemeMode.light;
  }
}

Future<void> _saveThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  switch (mode) {
    case ThemeMode.dark:
      await prefs.setString('theme_mode', 'dark');
      break;
    case ThemeMode.light:
      await prefs.setString('theme_mode', 'light');
      break;
    case ThemeMode.system:
      await prefs.setString('theme_mode', 'system');
      break;
  }
}

// Bildirim gösterme işlemi için global anahtar
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// Drawer menüsünü açmak için global scaffold key
final GlobalKey<ScaffoldState> globalScaffoldKey = GlobalKey<ScaffoldState>();

// Global bildirim fonksiyonu
void showGlobalSnackbar(String message, {Color backgroundColor = Colors.blue}) {
  try {
    // Eğer scaffold messenger key kullanılabilirse bildirimi göster
    final messenger = appScaffoldMessengerKey.currentState;
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
    }
  } catch (e) {
    print('Global bildirim gösterme hatası: $e');
  }
}

// Bildirim yönlendirmesi için global anahtar - artık her oturum için dinamik oluşturulacak
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Global hata yakalayıcı
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    logError('Flutter Error', details.exception, details.stack);
  };

  // Asenkron hataları yakalama
  PlatformDispatcher.instance.onError = (error, stack) {
    logError('Platform Dispatcher Error', error, stack);
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Timezone ayarlarını başlat
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

  // Supabase istemcisini başlat
  await Supabase.initialize(
    url: 'https://uvdcefauzxordqgvvweq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2ZGNlZmF1enhvcmRxZ3Z2d2VxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4MjE5NzEsImV4cCI6MjA4NjM5Nzk3MX0.WWyRB9PfOTgWq55oc1sXDDRomL0D5C6ydILGxTDrqWU',
  );

  supabase = Supabase.instance.client;

  // Bildirim servislerini uygulama açılışında başlat.
  // Not: Cold-start durumda bildirime tıklayarak açılış (payload yakalama) burada devreye girer.
  await NotificationService().init();

  // Workmanager'ı başlat (arka plan bildirimler için)
  await Workmanager().initialize(
    enhanced.BackgroundService.callbackDispatcher,
    isInDebugMode: kDebugMode,
  );

  // Periyodik bildirim kontrolü görevini başlat
  await Workmanager().registerPeriodicTask(
    "periodicNotificationCheck",
    Duration(hours: 1).inMilliseconds.toString(), // Her saat
    existingWorkPolicy: ExistingWorkPolicy.replace,
    backoffPolicy: BackoffPolicy.exponential,
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresCharging: false,
      requiresDeviceIdle: false,
    ),
  );

  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  try {
    // Android 13+ için bildirim izni
    final notificationStatus = await Permission.notification.request();
    print('Bildirim izni: $notificationStatus');

    // Depolama izni
    final storageStatus = await Permission.storage.request();
    print('Depolama izni: $storageStatus');

    // Android 10 ve üzeri için
    try {
      // Android 11 ve sonrası için
      final externalStorageStatus = await Permission.manageExternalStorage
          .request();
      print('Harici depolama yönetimi izni: $externalStorageStatus');
    } catch (e, stack) {
      logError("Harici depolama yönetimi izin hatası", e, stack);
    }

    // Tüm izinlerin durumunu logla
    final permissionsStatus = {
      'notification': await Permission.notification.status,
      'storage': await Permission.storage.status,
      'manageExternalStorage': await Permission.manageExternalStorage.status,
    };

    print("İzin Durumları: $permissionsStatus");
  } catch (e, stack) {
    logError('İzin isteme hatası', e, stack);
  }
}

// Çalışan hatırlatıcılarını kontrol et ve gerekirse test bildirimi gönder
Future<void> _checkAndTestEmployeeReminders() async {
  try {
    print('Çalışan hatırlatıcıları kontrol ediliyor...');

    // Bugün daha önce kontrol yapılıp yapılmadığını kontrol et
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final checkKey =
        'employee_reminder_checked_${now.year}_${now.month}_${now.day}';

    // Eğer bugün için kontrol yapılmamışsa, bildirim izinlerini ve sistem durumunu kontrol et
    if (!(prefs.getBool(checkKey) ?? false)) {
      print('Bugün için hatırlatıcı kontrolü yapılmamış, kontrol ediliyor...');

      // NotificationService'i kullanarak izinleri kontrol et
      final notificationService = NotificationService();

      // Mevcut kullanıcı ID'sini al
      final userId = await notificationService.getCurrentUserId();

      if (userId != null) {
        // Supabase'den çalışan hatırlatıcılarını getir
        print('Kullanıcının çalışan hatırlatıcıları getiriliyor...');

        try {
          // Bugünden sonraki ve tamamlanmamış hatırlatıcıları al
          final nowStr = now.toIso8601String();

          final List<dynamic> reminders = await supabase
              .from('employee_reminders')
              .select()
              .eq('user_id', userId)
              .eq('is_completed', 0)
              .gte('reminder_date', nowStr)
              .order('reminder_date', ascending: true);

          print(
            'Toplam ${reminders.length} aktif çalışan hatırlatıcısı bulundu',
          );

          if (reminders.isNotEmpty) {
            // Zamanlanmış bildirimleri kontrol et
            final pendingNotifications = await notificationService
                .getPendingNotifications();
            print(
              'Zamanlanmış bildirim sayısı: ${pendingNotifications.length}',
            );

            // Eğer hiç zamanlanmış bildirim yoksa veya hatırlatıcı sayısından az ise,
            // bir uyarı bildirimi gönder
            if (pendingNotifications.length < reminders.length) {
              print(
                'Zamanlanmış bildirim sayısı, hatırlatıcı sayısından az, uyarı bildirimi gösteriliyor...',
              );

              await notificationService.flutterLocalNotificationsPlugin.show(
                99999,
                'Hatırlatıcı Kontrolü',
                '${reminders.length} aktif hatırlatıcınız var. Bildirimlerin gösterilmesi için izinleri kontrol edin.',
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'reminder_check',
                    'Hatırlatıcı Kontrolleri',
                    channelDescription:
                        'Hatırlatıcıların çalışıp çalışmadığını kontrol etmek için gösterilen bildirimler',
                    importance: Importance.high,
                    priority: Priority.high,
                  ),
                  iOS: DarwinNotificationDetails(),
                ),
              );

              // İlk hatırlatıcı için hemen bir test bildirimi gönder
              if (reminders.isNotEmpty) {
                final firstReminder = reminders.first;
                final id = firstReminder['id'] as int;
                final workerName = firstReminder['worker_name'] as String;
                final message = firstReminder['message'] as String;
                final reminderDate = DateTime.parse(
                  firstReminder['reminder_date'] as String,
                );

                // Formatlanmış tarih/saat hazırla
                final dateStr =
                    '${reminderDate.day}/${reminderDate.month}/${reminderDate.year}';
                final timeStr =
                    '${reminderDate.hour.toString().padLeft(2, '0')}:${reminderDate.minute.toString().padLeft(2, '0')}';

                await notificationService.flutterLocalNotificationsPlugin.show(
                  99998,
                  'Yaklaşan Hatırlatıcı - $workerName',
                  '$message - $dateStr $timeStr tarihinde hatırlatılacak',
                  const NotificationDetails(
                    android: AndroidNotificationDetails(
                      'upcoming_reminder',
                      'Yaklaşan Hatırlatıcılar',
                      channelDescription:
                          'Yaklaşan hatırlatıcılar için gösterilen bildirimler',
                      importance: Importance.high,
                      priority: Priority.high,
                    ),
                    iOS: DarwinNotificationDetails(),
                  ),
                );
              }
            } else {
              print(
                'Tüm hatırlatıcılar için bildirimler doğru şekilde zamanlanmış',
              );
            }
          } else {
            print('Aktif çalışan hatırlatıcısı bulunmadı');
          }
        } catch (e) {
          print('Supabase sorgusunda hata: $e');

          // Hata durumunda bir test bildirimi gönder
          await notificationService.sendTestNotification();
        }

        // Kontrolün yapıldığını kaydet
        await prefs.setBool(checkKey, true);
        print('Hatırlatıcı kontrolü yapıldı ve kaydedildi: $checkKey');
      }
    } else {
      print('Bugün için hatırlatıcı kontrolü zaten yapılmış, tekrar edilmiyor');
    }
  } catch (e) {
    print('Çalışan hatırlatıcıları kontrol edilirken hata: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Uygulama açılışında oturum geri yükleme tamamlanana kadar güvenli varsayılan.
  bool _isLoggedIn = false;
  bool _isHandlingNotification =
      false; // Bildirim işleme durumunu tutan değişken
  static const String _notificationChannel = 'com.example.puantaj/notification';
  late BasicMessageChannel<String> _messageChannel;

  // Router yapılandırması için değişken - her oturum değişikliğinde yeniden oluşturulacak
  GoRouter _router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    ],
  );

  // Her oturum değişikliğinde yeniden oluşturulan navigator key
  late GlobalKey<NavigatorState> _navigatorKey;

  // Router hazır olduğunu takip eden değişken
  bool _isRouterReady = false;

  // Admin kontrolü için değişken
  bool _isCurrentUserAdmin = false;

  // Açılışta oturum geri yüklenirken router kurulmasını geciktirmek için.
  bool _isBootstrappingSession = true;

  @override
  void initState() {
    super.initState();

    // Oturum durumuna göre yeni bir navigator key oluştur
    _navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'appNavigator');

    // Uygulama açılışında kayıtlı oturumu geri yükle.
    // Böylece uygulama kapatılıp açıldığında login ekranına düşmez.
    _bootstrapSession();

    // Auth durumu değişikliklerini dinle
    authStateNotifier.addListener(() {
      // Hesap değiştirme modundaysa, login ekranına yönlendirmeyi engelle
      if (isSwitchingAccounts) {
        print(
          'Hesap değiştirme modu aktif, login ekranına yönlendirme engellendi',
        );
        return;
      }

      // Kullanıcı değişikliği durumunda UI güncelleme
      setState(() {
        _isLoggedIn = authStateNotifier.value;

        // Sadece çıkış yapıldığında yeni bir key oluştur
        if (!_isLoggedIn) {
          _navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'appNavigator');
          // Admin durumunu sıfırla
          _isCurrentUserAdmin = false;
        }

        // Router'ı yeniden yapılandır
        _initializeRouter();
      });
    });

    // Tema değişikliklerini dinle
    themeModeNotifier.addListener(() {
      if (mounted) {
        // Burada sadece UI'ı yenile, router veya diğer state değişkenlerini yeniden yapılandırma
        setState(() {
          print('Tema değişikliği algılandı: ${themeModeNotifier.value}');
        });
      }
    });

    // Kullanıcı veri değişikliklerini dinle
    userDataNotifier.addListener(() {
      if (mounted) {
        // Kullanıcı verileri değiştiğinde admin durumunu kontrol et
        _checkCurrentUserAdminStatus();
      }
    });

    // Android'den mesaj alma kanalını oluştur
    _messageChannel = const BasicMessageChannel<String>(
      _notificationChannel,
      StringCodec(),
    );

    // Android'den gelen bildirim mesajlarını dinle
    _messageChannel.setMessageHandler(_handlePlatformMessage);

    // Uygulama başlatıldığında özel olarak bildirim durumunu kontrol et
    _checkInitialNotification();
  }

  /// Uygulama açılışında yerel depolamadaki oturumu geri yükler.
  ///
  /// Not: Bu proje Supabase Auth yerine kendi kullanıcı tablosu ile giriş yaptığı için
  /// oturum bilgisi `SharedPreferences` üzerinde tutuluyor (`AuthService.userKey`).
  /// Bu nedenle açılışta `authStateNotifier` varsayılan false kalırsa router login'e düşer.
  Future<void> _bootstrapSession() async {
    try {
      print('Oturum geri yükleme başlatıldı...');
      setState(() {
        _isRouterReady = false;
        _isBootstrappingSession = true;
      });

      final authService = AuthService();
      final userId = await authService.getUserId();

      if (userId == null) {
        print('Kayıtlı oturum bulunamadı, login ekranı gösterilecek');
        authStateNotifier.value = false;
        _isLoggedIn = false;
        _isCurrentUserAdmin = false;
      } else {
        print(
          'Kayıtlı oturum bulundu: userId=$userId. Kullanıcı verisi yükleniyor...',
        );

        final user = await authService.currentUser;
        if (user == null) {
          // Kaydedilmiş userId var ama kullanıcı verisi alınamıyorsa, güvenli tarafta kalıp
          // login'e düşelim. (Ağ hatası vs. olabilir; istersen bu davranışı daha sonra
          // "offline mod" gibi genişletebiliriz.)
          print('Kullanıcı verisi alınamadı, login ekranı gösterilecek');
          authStateNotifier.value = false;
          _isLoggedIn = false;
          _isCurrentUserAdmin = false;
        } else {
          // Admin durumunu hesapla
          final dynamic isAdminValue = user['is_admin'];
          final String username = (user['username'] as String).toLowerCase();

          bool isAdmin = false;
          if (isAdminValue is int) {
            isAdmin = isAdminValue == 1;
          } else if (isAdminValue is bool) {
            isAdmin = isAdminValue;
          }
          if (username == 'admin') {
            isAdmin = true;
          }

          _isCurrentUserAdmin = isAdmin;
          _isLoggedIn = true;
          authStateNotifier.value = true;

          print('Oturum geri yüklendi. isAdmin=$isAdmin, username=$username');
        }
      }
    } catch (e, stack) {
      logError('Oturum geri yükleme hatası', e, stack);
      authStateNotifier.value = false;
      _isLoggedIn = false;
      _isCurrentUserAdmin = false;
    } finally {
      if (!mounted) return;
      setState(() {
        _isBootstrappingSession = false;
      });

      // Router'ı mevcut oturum durumuna göre kur.
      _initializeRouter();
    }
  }

  // Router'ı yapılandır
  void _initializeRouter() {
    // Router yapılandırılıyor olarak işaretle
    _isRouterReady = false;
    print('Router yapılandırılıyor, oturum durumu: $_isLoggedIn');

    // Giriş yapmış kullanıcı için başlangıç konumunu belirle
    Future<String> _determineInitialLocation() async {
      // Bildirimden açılış varsa (cold start / reopen), initialLocation'ı mutlaka bildirimin hedefi yap.
      // Not: Aksi halde uygulama /home'a (ve son seçilen sekmeye) düşerek bildirimin yönlendirmesini ezebiliyor.
      try {
        final prefs = await SharedPreferences.getInstance();
        final launchedFromNotification =
            prefs.getBool('launched_from_notification') ?? false;
        final notificationNeedsHandling =
            prefs.getBool('notification_needs_handling') ?? false;

        if ((launchedFromNotification || notificationNeedsHandling) &&
            _isLoggedIn) {
          final payload = prefs.getString('last_notification_payload');
          print('InitialLocation: Bildirim tespit edildi, payload=$payload');

          if (payload == null) {
            return '/attendance';
          }

          // Eski format
          if (payload == 'attendance_reminder' ||
              payload == 'daily_attendance_reminder') {
            return '/attendance';
          }

          // Yeni format (JSON)
          try {
            final payloadData = jsonDecode(payload) as Map<String, dynamic>;
            final String type = payloadData['type'] as String;
            final int? reminderId = payloadData['reminder_id'] as int?;

            if (type == 'attendance_reminder' ||
                type == 'daily_attendance_reminder') {
              return '/attendance';
            }

            if (type.startsWith('employee_reminder_') ||
                type.startsWith('employee_reminder_check_') ||
                type.startsWith('employee_reminder_soon_')) {
              if (reminderId != null) {
                await prefs.setInt('active_employee_reminder_id', reminderId);
              }
              return '/employee_reminder_detail';
            }
          } catch (e) {
            print('InitialLocation: Payload ayrıştırma hatası: $e');
          }

          // Payload çözümlenemiyorsa güvenli varsayılan
          return '/attendance';
        }
      } catch (e) {
        print('InitialLocation: Bildirim kontrolü hatası: $e');
      }

      // Hesap değiştirme modundaysa, login ekranına yönlendirmeyi engelle
      if (isSwitchingAccounts) {
        print(
          'Hesap değiştirme modu aktif, başlangıç konum belirlenmesi atlanıyor',
        );
        // Admin mi kontrolü yap
        try {
          final user = await AuthService().currentUser;
          final dynamic isAdminValue = user?['is_admin'];
          final bool isAdmin =
              isAdminValue == 1 ||
              isAdminValue == true ||
              (user?['username'] as String?)?.toLowerCase() == 'admin';

          if (isAdmin) {
            return '/admin_accounts';
          } else {
            return '/home';
          }
        } catch (e) {
          print('Hesap değiştirme sırasında hata: $e');
          return '/home';
        }
      }

      if (!_isLoggedIn) {
        return '/login';
      } else {
        // Admin kontrolü yap
        try {
          final user = await AuthService().currentUser;
          if (user != null) {
            // Kullanıcı verilerini göster
            print('Kullanıcı verileri: ${user.toString()}');

            // is_admin değerini kontrol et
            final dynamic isAdminValue = user['is_admin'];
            final String username = (user['username'] as String).toLowerCase();

            // Değerleri ayrı ayrı göster
            print(
              'is_admin değeri: $isAdminValue (${isAdminValue.runtimeType})',
            );
            print('username değeri: $username');

            // Admin kontrolü - is_admin = 1 (veya true) veya username = 'admin'
            _isCurrentUserAdmin = false;

            // is_admin türüne göre kontrol et
            if (isAdminValue is int) {
              _isCurrentUserAdmin = isAdminValue == 1;
            } else if (isAdminValue is bool) {
              _isCurrentUserAdmin = isAdminValue;
            }

            // Kullanıcı adı 'admin' ise her zaman admin kabul et
            if (username == 'admin') {
              _isCurrentUserAdmin = true;
            }

            print('Admin kontrolü sonucu: $_isCurrentUserAdmin');
          } else {
            _isCurrentUserAdmin = false;
            print('Kullanıcı bilgisi alınamadı');
          }

          print('Mevcut kullanıcı admin mi: $_isCurrentUserAdmin');
          // Admin ise direkt admin paneline, değilse ana sayfaya yönlendir
          return _isCurrentUserAdmin ? '/admin_accounts' : '/home';
        } catch (e) {
          print('Admin kontrolü sırasında hata: $e');
          _isCurrentUserAdmin =
              false; // Hata durumunda admin değil olarak kabul et
          return '/home'; // Hata durumunda varsayılan olarak ana sayfaya yönlendir
        }
      }
    }

    // Başlangıç konumunu belirleme işlemi
    _determineInitialLocation().then((initialLocation) {
      print('Başlangıç konumu belirlendi: $initialLocation');

      // Admin durumunu bir kez daha kontrol et ve vurgula
      print(
        'ROUTER YAPILANDIRMASI ÖNCESİ KONTROL: Admin mi? => $_isCurrentUserAdmin',
      );

      // GoRouter'ı yapılandır
      _router = GoRouter(
        initialLocation: initialLocation,
        navigatorKey: _isLoggedIn ? _navigatorKey : null,
        debugLogDiagnostics: true,
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/report',
            builder: (context, state) => const ReportScreen(),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminPanelScreen(),
          ),
          GoRoute(
            path: '/admin_accounts',
            builder: (context, state) =>
                const AdminPanelScreen(initialTabIndex: 1),
          ),
          GoRoute(
            path: '/attendance',
            builder: (context, state) {
              // Yevmiye ekranı HomeScreen içindeki sekmelerden biri.
              // Bu route'a doğrudan AttendanceScreen bağlanırsa drawer görünmez.
              if (globalSelectedIndexNotifier != null) {
                globalSelectedIndexNotifier!.value = 1;
              }
              return const HomeScreen();
            },
          ),
          GoRoute(
            path: '/notification_settings',
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: '/employee_reminder_detail',
            builder: (context, state) {
              // Hatırlatıcı detay sayfasını ana ekranın bir parçası olarak göster
              return const EmployeeReminderDetailScreen();
            },
          ),
          GoRoute(
            path: '/notification_test',
            builder: (context, state) => const NotificationTestScreen(),
          ),
        ],
        redirect: (context, state) async {
          final location = state.matchedLocation;
          final loggingIn = location == '/login' || location == '/register';

          // Redirect işlemi başlıyor
          print(
            'Router redirect: location=$location, isLoggedIn=$_isLoggedIn, isAdmin=$_isCurrentUserAdmin, isSwitchingAccounts=$isSwitchingAccounts',
          );

          // Hesap değiştirme modundaysa yönlendirme yapma - aynı tür hesaplar arası geçişi izin ver
          if (isSwitchingAccounts) {
            print('Hesap değiştirme modu aktif, yönlendirme atlanıyor');
            return null; // Hiçbir yönlendirme yapma
          }

          // Çıkış yapıldığında veya giriş yapılmadığında login sayfasına yönlendir
          if (!_isLoggedIn && !loggingIn) {
            // Yalnızca hesap değiştirme modu KAPALI ise login'e yönlendir
            if (!isSwitchingAccounts) {
              print('Oturum açılmamış, login sayfasına yönlendiriliyor');
              return '/login';
            } else {
              print(
                'Hesap değiştirme modunda olduğu için login yönlendirmesi atlanıyor',
              );
              return null;
            }
          }

          // Giriş yapmış kullanıcıyı uygun sayfaya yönlendir
          if (_isLoggedIn) {
            // Login veya register sayfasındaysa
            if (loggingIn) {
              // Bildirimden açılma durumunu kontrol et
              try {
                final prefs = await SharedPreferences.getInstance();
                final launchedFromNotification =
                    prefs.getBool('launched_from_notification') ?? false;

                // Eğer bildirimden açıldıysa, payload'a göre doğru sayfaya yönlendir.
                // Not: Aksi halde router açılışta /home'a düşerek bildirimin hedefini ezebiliyor.
                if (launchedFromNotification) {
                  final payload = prefs.getString('last_notification_payload');
                  if (payload != null) {
                    try {
                      // Eski format
                      if (payload == 'attendance_reminder' ||
                          payload == 'daily_attendance_reminder') {
                        return '/attendance';
                      }

                      // Yeni format (JSON)
                      final payloadData =
                          jsonDecode(payload) as Map<String, dynamic>;
                      final String type = payloadData['type'] as String;

                      if (type == 'attendance_reminder' ||
                          type == 'daily_attendance_reminder') {
                        return '/attendance';
                      }

                      if (type.startsWith('employee_reminder_') ||
                          type.startsWith('employee_reminder_check_') ||
                          type.startsWith('employee_reminder_soon_')) {
                        return '/employee_reminder_detail';
                      }
                    } catch (e) {
                      print(
                        'MyApp: Bildirim payload hedefi ayrıştırılamadı, varsayılan akışa dönülüyor. Hata: $e',
                      );
                    }
                  }

                  // Payload yoksa veya ayrıştırılamadıysa güvenli varsayılan: yevmiye.
                  // Amaç: /home (son sekme) veya bildirim ayarları gibi sayfaların hedefi ezmesini engellemek.
                  return '/attendance';
                }
              } catch (e) {
                print('MyApp: Bildirim durumu kontrolünde hata: $e');
              }

              // Admin kontrolünü _isCurrentUserAdmin değişkeni üzerinden yapalım
              // Bu sayede her redirect çağrısında tekrar tekrar API'ye istek atmamış oluruz
              print(
                'Giriş sayfasından yönlendirme: isAdmin=$_isCurrentUserAdmin',
              );
              final targetPath = _isCurrentUserAdmin
                  ? '/admin_accounts'
                  : '/home';
              print('Yönlendirme hedefi: $targetPath');
              return targetPath;
            }

            // Admin sayfaları kontrolü
            // Admin kullanıcısı normal sayfaya erişmeye çalışırsa engelleme
            if (_isCurrentUserAdmin &&
                !location.startsWith('/admin') &&
                location != '/admin_accounts') {
              // Bildirim kontrollerini atla
              if (location == '/notification_settings' ||
                  location == '/employee_reminder_detail') {
                return null; // Bu sayfalara her kullanıcı erişebilir
              }

              // Yevmiye kontrollerini atla
              if (location == '/attendance') {
                return null; // Bu sayfaya her kullanıcı erişebilir
              }

              print(
                'Admin kullanıcı yanlış sayfada ($location), admin paneline yönlendiriliyor',
              );
              return '/admin_accounts';
            }

            // Normal kullanıcı admin sayfasındaysa
            if (!_isCurrentUserAdmin &&
                (location == '/admin' || location == '/admin_accounts')) {
              print(
                'Normal kullanıcı admin sayfasında, ana sayfaya yönlendiriliyor',
              );
              return '/home';
            }
          }

          print('Redirect işlemi: herhangi bir yönlendirme yapılmadı');
          return null;
        },
        errorBuilder: (context, state) => Scaffold(
          body: Center(
            child: Text(
              'Sayfa bulunamadı: ${state.uri}',
              style: const TextStyle(fontSize: 20.0),
            ),
          ),
        ),
      );

      // Router yapılandırması tamamlandığında UI'ı güncelle
      _isRouterReady = true;
      print('Router yapılandırması tamamlandı, UI güncelleniyor');
      if (mounted) {
        setState(() {});
      }
    });
  }

  // Platform'dan gelen mesajları işle
  Future<String> _handlePlatformMessage(String? message) async {
    print('Android\'den mesaj alındı: $message');

    if (message == null) {
      return 'Mesaj boş';
    }

    try {
      // Yeni format payload'ı ayrıştırmayı dene
      Map<String, dynamic>? payloadData;
      try {
        payloadData = jsonDecode(message) as Map<String, dynamic>;
      } catch (e) {
        print('Mesaj JSON formatında değil, eski format olabilir: $e');
      }

      // Eğer yeni format payload tespit edildiyse
      if (payloadData != null &&
          payloadData.containsKey('type') &&
          payloadData.containsKey('user_id')) {
        // Bildirim tipini ve kullanıcı bilgilerini al
        final String type = payloadData['type'] as String;
        final int userId = payloadData['user_id'] as int;
        final String username = payloadData['username'] as String;
        final String fullName = payloadData['full_name'] as String;
        final int? reminderId = payloadData['reminder_id'] as int?;

        print(
          'Gelişmiş bildirim alındı: type=$type, userId=$userId, username=$username',
        );

        // Mevcut kullanıcıyı kontrol et
        final currentUser = await AuthService().currentUser;
        final currentUserId = currentUser?['id'] as int?;

        // Eğer başka bir kullanıcıya ait bildirimse, o hesaba geçiş yap
        if (currentUserId != userId) {
          print('Bildirim farklı bir hesaba ait, hesap değiştiriliyor...');

          // Eğer zaten bir bildirim işlenmiyorsa işleme başla
          if (!_isHandlingNotification) {
            _isHandlingNotification = true;

            // Hesaba geçiş yap
            final success = await AuthService().switchToSavedAccount(
              userId: userId,
              username: username,
            );

            if (success) {
              print('Hesaba başarıyla geçiş yapıldı: $fullName');

              // Kısa bir gecikme ekle (UI'ın hazırlanmasına izin vermek için)
              await Future.delayed(const Duration(milliseconds: 500));

              // Bildirim tipine göre yönlendirme yap
              if (type == 'attendance_reminder' ||
                  type == 'daily_attendance_reminder') {
                // Yevmiye sayfasına yönlendir
                if (globalSelectedIndexNotifier != null) {
                  print('Ana sayfada yevmiye sekmesi seçiliyor (index: 1)');
                  globalSelectedIndexNotifier!.value = 1;
                }

                if (_navigatorKey.currentContext != null) {
                  print('Ana sayfaya yönlendiriliyor...');
                  _router.go('/home');
                }
              } else if (type.startsWith('employee_reminder_') ||
                  type.startsWith('employee_reminder_check_') ||
                  type.startsWith('employee_reminder_soon_') ||
                  type.startsWith('employee_reminder_confirmation_')) {
                // Çalışan hatırlatıcısı bildirimi
                print('Çalışan hatırlatıcısı bildirimi alındı: $reminderId');

                // Hatırlatıcı ID'sini kaydet
                final prefs = await SharedPreferences.getInstance();
                if (reminderId != null) {
                  await prefs.setInt('active_employee_reminder_id', reminderId);
                } else {
                  // ID'yi tip bilgisinden çıkarmayı dene
                  try {
                    final parts = type.split('_');
                    if (parts.length >= 3) {
                      final idStr = parts.last;
                      final id = int.parse(idStr);
                      await prefs.setInt('active_employee_reminder_id', id);
                    }
                  } catch (e) {
                    print('Bildirim tipinden ID çıkarılamadı: $type');
                  }
                }

                if (_navigatorKey.currentContext != null) {
                  print(
                    'Çalışan hatırlatıcısı detay sayfasına yönlendiriliyor...',
                  );
                  // Drawer menüsünün görünmesi için scaffold key'i kullanıyoruz
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _router.go('/employee_reminder_detail');

                    // Drawer'ı açmak için scaffold key'i kullan
                    if (globalScaffoldKey.currentState != null) {
                      globalScaffoldKey.currentState!.openDrawer();
                    }
                  });
                }
              }

              // Bildirimleri temizle
              NotificationService().clearAllNotifications();
            } else {
              print('Hesaba geçiş başarısız oldu');
            }

            // İşlem tamamlandıktan sonra bayrağı sıfırla
            Future.delayed(const Duration(seconds: 2), () {
              _isHandlingNotification = false;
            });
          }
        } else {
          // Aynı hesaba ait bildirimse, sadece yönlendirme yap
          print('Bildirim mevcut hesaba ait, sadece yönlendirme yapılacak');

          // Eğer zaten bir bildirim işlenmiyorsa işleme başla
          if (!_isHandlingNotification) {
            _isHandlingNotification = true;

            // Kısa bir gecikme ekle (UI'ın hazırlanmasına izin vermek için)
            Future.delayed(const Duration(milliseconds: 500), () async {
              // Bildirim tipine göre yönlendirme yap
              if (type == 'attendance_reminder' ||
                  type == 'daily_attendance_reminder') {
                // Yevmiye sayfasına yönlendir
                if (globalSelectedIndexNotifier != null) {
                  print('Ana sayfada yevmiye sekmesi seçiliyor (index: 1)');
                  globalSelectedIndexNotifier!.value = 1;
                }

                if (_navigatorKey.currentContext != null) {
                  print('Ana sayfaya yönlendiriliyor...');
                  _router.go('/home');
                }
              } else if (type.startsWith('employee_reminder_') ||
                  type.startsWith('employee_reminder_check_') ||
                  type.startsWith('employee_reminder_soon_') ||
                  type.startsWith('employee_reminder_confirmation_')) {
                // Çalışan hatırlatıcısı bildirimi
                print('Çalışan hatırlatıcısı bildirimi alındı: $reminderId');

                // Hatırlatıcı ID'sini kaydet
                final prefs = await SharedPreferences.getInstance();
                if (reminderId != null) {
                  await prefs.setInt('active_employee_reminder_id', reminderId);
                } else {
                  // ID'yi tip bilgisinden çıkarmayı dene
                  try {
                    final parts = type.split('_');
                    if (parts.length >= 3) {
                      final idStr = parts.last;
                      final id = int.parse(idStr);
                      await prefs.setInt('active_employee_reminder_id', id);
                    }
                  } catch (e) {
                    print('Bildirim tipinden ID çıkarılamadı: $type');
                  }
                }

                if (_navigatorKey.currentContext != null) {
                  print(
                    'Çalışan hatırlatıcısı detay sayfasına yönlendiriliyor...',
                  );
                  // Drawer menüsünün görünmesi için scaffold key'i kullanıyoruz
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _router.go('/employee_reminder_detail');

                    // Drawer'ı açmak için scaffold key'i kullan
                    if (globalScaffoldKey.currentState != null) {
                      globalScaffoldKey.currentState!.openDrawer();
                    }
                  });
                }
              }

              // İşlem tamamlandı, durumu güncelle
              Future.delayed(const Duration(seconds: 2), () {
                _isHandlingNotification = false;
              });
            });
          }
        }

        return 'Gelişmiş bildirim işlendi';
      }

      // Eski format bildirimler için geriye dönük uyumluluk
      if (message == 'attendance_reminder' ||
          message == 'daily_attendance_reminder') {
        // Eğer zaten bir bildirim işlenmiyorsa işleme başla
        if (!_isHandlingNotification) {
          _isHandlingNotification = true;

          print(
            'Android\'den bildirim mesajı alındı, yevmiye sayfasına yönlendiriliyor...',
          );

          // Kısa bir gecikme ekle (UI'ın hazırlanmasına izin vermek için)
          Future.delayed(const Duration(milliseconds: 500), () async {
            // Yevmiye sekmesini seç
            if (globalSelectedIndexNotifier != null) {
              print('Ana sayfada yevmiye sekmesi seçiliyor (index: 1)');
              globalSelectedIndexNotifier!.value = 1;
            }

            // Ana sayfaya git
            if (_navigatorKey.currentContext != null) {
              print('Ana sayfaya yönlendiriliyor...');
              _router.go('/home');
            }

            // Bildirimleri temizle
            NotificationService().clearAllNotifications();

            // İşlem tamamlandıktan sonra bayrağı sıfırla
            Future.delayed(const Duration(seconds: 2), () {
              _isHandlingNotification = false;
            });
          });
        }
      } else if (message.startsWith('employee_reminder_')) {
        // Çalışan hatırlatıcısı bildirimi
        if (!_isHandlingNotification) {
          _isHandlingNotification = true;

          print('Çalışan hatırlatıcısı bildirimi alındı: $message');

          try {
            // Bildirim ID'sini al
            final reminderId = int.parse(
              message.replaceFirst('employee_reminder_', ''),
            );

            // SharedPreferences'a kaydet
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('active_employee_reminder_id', reminderId);

            // Bildirim ayarları sayfasına yönlendir
            Future.delayed(const Duration(milliseconds: 500), () async {
              if (_navigatorKey.currentContext != null) {
                print(
                  'Çalışan hatırlatıcısı detay sayfasına yönlendiriliyor...',
                );
                // Drawer menüsünün görünmesi için scaffold key'i kullanıyoruz
                Future.delayed(const Duration(milliseconds: 300), () {
                  _router.go('/employee_reminder_detail');

                  // Drawer'ı açmak için scaffold key'i kullan
                  if (globalScaffoldKey.currentState != null) {
                    globalScaffoldKey.currentState!.openDrawer();
                  }
                });
              }

              // İşlem tamamlandıktan sonra bayrağı sıfırla
              Future.delayed(const Duration(seconds: 2), () {
                _isHandlingNotification = false;
              });
            });
          } catch (e) {
            print('Çalışan hatırlatıcısı işlenirken hata: $e');
            _isHandlingNotification = false;
          }
        }
      }
    } catch (e) {
      print('Platform mesajı işlenirken hata: $e');
    }

    return 'Mesaj alındı';
  }

  // Uygulama ilk açıldığında bildirim durumunu kontrol et
  Future<void> _checkInitialNotification() async {
    print('Uygulama başlatıldı, bildirim durumu kontrol ediliyor...');

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool launchedFromNotification =
          prefs.getBool('launched_from_notification') ?? false;
      bool notificationNeedsHandling =
          prefs.getBool('notification_needs_handling') ?? false;

      if ((launchedFromNotification || notificationNeedsHandling) &&
          _isLoggedIn) {
        // Bildirimden açılışta sadece işaretleri temizle ve bildirimleri temizle.
        // Yönlendirmeyi router'ın initialLocation ve redirect halletsin.
        // Not: _router.go() çağrısı ile initialLocation arasında çakışma oluyordu.
        print(
          'Uygulama bildirimden başlatıldı, yönlendirme router tarafından yapılacak',
        );

        // Bildirimleri temizle ve işleme durumunu güncelle
        _isHandlingNotification = true;
        NotificationService().clearAllNotifications();

        // İşaretleri temizle
        await prefs.setBool('launched_from_notification', false);
        await prefs.setBool('notification_needs_handling', false);
        await prefs.setBool('flutter.notification_needs_handling', false);

        // İşlem tamamlandığında bayrağı sıfırla
        Future.delayed(const Duration(seconds: 3), () {
          _isHandlingNotification = false;
        });
      }
    } catch (e) {
      print('Bildirim durumu kontrolünde hata: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Mevcut kullanıcının admin durumunu kontrol et ve _isCurrentUserAdmin değişkenini güncelle
  void _checkCurrentUserAdminStatus() {
    final userData = userDataNotifier.value;
    if (userData == null) {
      _isCurrentUserAdmin = false;
      return;
    }

    try {
      // is_admin değerini kontrol et
      final dynamic isAdminValue = userData['is_admin'];
      final String username = (userData['username'] as String).toLowerCase();

      print('userDataNotifier değişti, admin kontrolü yapılıyor...');
      print('is_admin değeri: $isAdminValue (${isAdminValue.runtimeType})');
      print('username değeri: $username');

      bool isAdmin = false;

      // is_admin türüne göre kontrol et
      if (isAdminValue is int) {
        isAdmin = isAdminValue == 1;
      } else if (isAdminValue is bool) {
        isAdmin = isAdminValue;
      }

      // Kullanıcı adı 'admin' ise her zaman admin kabul et
      if (username == 'admin') {
        isAdmin = true;
      }

      // Admin durumunda değişiklik varsa güncelle
      if (_isCurrentUserAdmin != isAdmin) {
        setState(() {
          _isCurrentUserAdmin = isAdmin;
          print('Admin durumu güncellendi: $_isCurrentUserAdmin');

          // Admin durumu değiştiyse router'ı yeniden yapılandır
          _initializeRouter();
        });
      }
    } catch (e) {
      print('Admin durumu kontrol edilirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Router yapılandırmasını kullan
    final appRouter = _router;

    // Açılışta oturum geri yüklenirken ve router hazırlanırken yükleme ekranı göster.
    // Böylece oturum restore edilmeden /login'e düşme gibi istenmeyen yönlendirmeler önlenir.
    if (_isBootstrappingSession || !_isRouterReady) {
      return MaterialApp(
        scaffoldMessengerKey: appScaffoldMessengerKey,
        title: 'Puantaj',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeModeNotifier.value,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    // Tema değişikliklerini verimli şekilde uygulamak için ValueListenableBuilder kullan
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: authStateNotifier,
          builder: (context, isAuthenticated, child) {
            return MaterialApp.router(
              scaffoldMessengerKey:
                  appScaffoldMessengerKey, // Global mesajlar için key ekle
              title: 'Puantaj',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              routerConfig: appRouter,
              builder: (context, child) {
                return ResponsiveBreakpoints.builder(
                  child: child!,
                  breakpoints: [
                    const Breakpoint(start: 0, end: 450, name: 'MOBILE'),
                    const Breakpoint(start: 451, end: 800, name: 'TABLET'),
                    const Breakpoint(start: 801, end: 1920, name: 'DESKTOP'),
                    const Breakpoint(
                      start: 1921,
                      end: double.infinity,
                      name: '4K',
                    ),
                  ],
                );
              },
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
              locale: const Locale('tr', 'TR'),
            );
          },
        );
      },
    );
  }
}
