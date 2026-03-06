import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puantaj/config/index.dart';
import 'package:puantaj/core/app_bootstrap.dart';
import 'package:puantaj/core/app_globals.dart';
import 'package:puantaj/core/app_notification_handler.dart';
// ⚡ PHASE 3: app_state.dart artık kullanılmıyor (Riverpod'a geçildi)
// import 'package:puantaj/core/app_state.dart'; // DEPRECATED
import 'package:puantaj/core/error_handler.dart';
import 'package:puantaj/core/user_data_notifier.dart';
import 'package:puantaj/core/providers/theme_provider.dart';
import 'package:puantaj/core/providers/auth_provider.dart';
import 'package:puantaj/firebase_options.dart';
import 'package:puantaj/services/fcm_service.dart';
import 'package:puantaj/services/notification/notification_helpers.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ⚡ Performans: Const breakpoints tanımı
const kResponsiveBreakpoints = [
  Breakpoint(start: 0, end: 450, name: 'MOBILE'),
  Breakpoint(start: 451, end: 800, name: 'TABLET'),
  Breakpoint(start: 801, end: 1920, name: 'DESKTOP'),
  Breakpoint(start: 1921, end: double.infinity, name: '4K'),
];

void main() async {
  // Global hata yakalayıcılar
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    logError('Flutter Error', details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    logError('Platform Dispatcher Error', error, stack);
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();

  // .env dosyasını yükle
  await dotenv.load(fileName: '.env');

  // Firebase'i başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize all services
  await ServiceInitializer.initialize();

  // Get Supabase client reference
  supabase = Supabase.instance.client;

  // Kaydedilmiş tema tercihini yükle
  await loadSavedThemeMode();

  // FCM servisini başlat
  await FCMService.instance.initialize();

  // ⚡ PHASE 3: Riverpod ProviderScope ile sarmalama
  runApp(const ProviderScope(child: MyApp()));
}

// ⚡ PHASE 3: ConsumerStatefulWidget'a geçiş
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isLoggedIn = false;
  bool _isHandlingNotification = false;
  static const String _notificationChannel = 'com.example.puantaj/notification';
  late BasicMessageChannel<String> _messageChannel;

  GoRouter? _router;
  late GlobalKey<NavigatorState> _navigatorKey;
  bool _isRouterReady = false;
  bool _isCurrentUserAdmin = false;
  bool _isBootstrappingSession = true;

  StreamSubscription<String>? _notificationClickSubscription;

  // ⚡ PHASE 3: AppState notifier kaldırıldı, Riverpod kullanılacak
  // late final ValueNotifier<AppState> _appStateNotifier; // DEPRECATED

  @override
  void initState() {
    super.initState();

    _navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'appNavigator');

    // ⚡ PHASE 3: Riverpod ThemeProvider kullanılacak, AppState notifier kaldırıldı
    // _appStateNotifier artık gerekli değil, Riverpod watch ile dinlenecek

    _bootstrapSession();

    // Bildirim tıklama olaylarını dinle
    _notificationClickSubscription = notificationClickStream.stream.listen(
      (payload) {
        debugPrint('📱 Notification click event alındı: $payload');
        _handleNotificationClick(payload);
      },
      onError: (error) {
        debugPrint('❌ Notification click stream hatası: $error');
      },
    );

    // ⚡ PHASE 3: Riverpod AuthProvider listener - ref.listen ile
    // authStateNotifier.addListener(_onAuthStateChanged); // DEPRECATED

    // Kullanıcı veri değişikliklerini dinle
    userDataNotifier.addListener(_onUserDataChanged);

    // Android'den mesaj alma kanalını oluştur
    _messageChannel = const BasicMessageChannel<String>(
      _notificationChannel,
      StringCodec(),
    );
    _messageChannel.setMessageHandler(_handlePlatformMessage);
  }

  /// Uygulama açılışında oturum ve bildirim durumunu yönetir
  Future<void> _bootstrapSession() async {
    try {
      ErrorHandler.logInfo('Bootstrap', 'Session başlatılıyor...');
      setState(() {
        _isRouterReady = false;
        _isBootstrappingSession = true;
      });

      // Bildirim durumunu kontrol et
      await AppBootstrap.checkInitialNotificationState();

      // Çalışan oturumunu kontrol et
      final workerSession = await AppBootstrap.checkWorkerSession();

      if (workerSession != null) {
        _isLoggedIn = false;
        _isCurrentUserAdmin = false;
        // ⚡ PHASE 3: Riverpod AuthProvider kullan
        ref.read(authStateProvider.notifier).logout();

        setState(() {
          _isBootstrappingSession = false;
        });

        _initializeRouter();
        return;
      }

      // Kullanıcı oturumunu kontrol et
      final userSession = await AppBootstrap.checkUserSession();

      if (userSession == null) {
        // ⚡ PHASE 3: Riverpod AuthProvider kullan
        ref.read(authStateProvider.notifier).logout();
        _isLoggedIn = false;
        _isCurrentUserAdmin = false;
      } else {
        _isCurrentUserAdmin = userSession['isAdmin'] as bool;
        _isLoggedIn = true;
        // ⚡ PHASE 3: Riverpod AuthProvider kullan
        ref.read(authStateProvider.notifier).login();
      }
    } catch (e, stack) {
      ErrorHandler.logError('Bootstrap.session', e, stack);
      // ⚡ PHASE 3: Riverpod AuthProvider kullan
      ref.read(authStateProvider.notifier).logout();
      _isLoggedIn = false;
      _isCurrentUserAdmin = false;
    } finally {
      if (!mounted) {
        ErrorHandler.logWarning(
          'Bootstrap',
          'Widget unmounted, işlem iptal edildi',
        );
        setState(() {
          _isBootstrappingSession = false;
        });
        return;
      }

      // Bildirim işleme
      ErrorHandler.logInfo('Bootstrap', 'Initial notification işleniyor...');
      try {
        await AppNotificationHandler.processInitialNotificationForRouting();
      } catch (e, stack) {
        ErrorHandler.logError('Bootstrap.processNotification', e, stack);
      }

      setState(() {
        _isBootstrappingSession = false;
      });

      // Router'ı kur
      ErrorHandler.logInfo('Bootstrap', 'Router initialize ediliyor...');
      _initializeRouter();
    }
  }

  // ⚡ PHASE 3: Riverpod AuthProvider listener
  void _onAuthStateChanged(bool? previous, bool next) {
    debugPrint('🔔 Auth state listener tetiklendi: $_isLoggedIn -> $next');

    // Sadece login durumu değiştiyse işlem yap
    if (_isLoggedIn != next) {
      _isLoggedIn = next;

      if (_isLoggedIn) {
        debugPrint('🔐 Auth state değişti: Giriş yapıldı');

        // Admin durumunu güncelle
        final userData = userDataNotifier.value;
        final isAdmin = AppBootstrap.checkAdminStatus(userData);
        _isCurrentUserAdmin = isAdmin;

        // Router'ı yeniden oluştur
        if (mounted) {
          setState(() {
            _isRouterReady = false;
          });
          _initializeRouter();
        }

        // UserData listener'ını tekrar ekle (çıkış sırasında kaldırılmıştı)
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _isLoggedIn) {
            userDataNotifier.removeListener(_onUserDataChanged);
            userDataNotifier.addListener(_onUserDataChanged);
            debugPrint('✅ UserData listener tekrar eklendi');
          }
        });
      } else {
        debugPrint('🔐 Auth state değişti: Çıkış yapıldı');

        // UserData listener'ını kaldır
        userDataNotifier.removeListener(_onUserDataChanged);

        // State'i temizle
        _isCurrentUserAdmin = false;
        _navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'appNavigator');

        // Direkt router'ı yeniden oluştur (loading yok)
        if (mounted) {
          setState(() {
            _isRouterReady = false;
          });
          _initializeRouter(forceInitialLocation: '/login');
        }

        debugPrint('✅ Çıkış işlemi tamamlandı');
      }
    } else {
      debugPrint('⚠️ Auth state değişmedi, işlem yapılmıyor');
    }
  }

  // ⚡ PHASE 3: _onThemeChanged kaldırıldı, Riverpod kullanılacak
  // void _onThemeChanged() { ... } // DEPRECATED

  void _onUserDataChanged() {
    if (!mounted) return;

    final userData = userDataNotifier.value;

    // KRITIK: userData null ise (logout sırasında) işlem yapma
    if (userData == null) {
      debugPrint('👤 User data null oldu (logout), işlem yapılmıyor');
      return;
    }

    final newAdminStatus = AppBootstrap.checkAdminStatus(userData);

    // KRITIK: Sadece login durumundayken admin değişikliklerini işle
    // Login/logout sırasında userDataNotifier değişiklikleri görmezden gel
    if (!_isLoggedIn) {
      debugPrint(
        '👤 User data değişti ama logged out durumda, işlem yapılmıyor',
      );
      return;
    }

    // Sadece admin durumu değiştiyse router'ı yeniden oluştur
    if (newAdminStatus != _isCurrentUserAdmin) {
      debugPrint('👤 User data değişti, admin kontrolü yapılıyor');
      _checkCurrentUserAdminStatus();
    } else {
      debugPrint(
        '👤 User data değişti ama admin durumu aynı ($_isCurrentUserAdmin)',
      );
    }
  }

  void _initializeRouter({String? forceInitialLocation}) {
    try {
      debugPrint('🛣️ Router yapılandırılıyor...');

      final userData = userDataNotifier.value;
      final isWorkerSession =
          userData != null && userData['id'] is String && !_isLoggedIn;

      // forceInitialLocation parametresi varsa onu kullan, yoksa default davranış
      final location =
          forceInitialLocation ?? (isWorkerSession ? '/worker/home' : '/home');

      _router = AppRoutes.createRouter(
        isLoggedIn: _isLoggedIn,
        isCurrentUserAdmin: _isCurrentUserAdmin,
        navigatorKey: _isLoggedIn ? _navigatorKey : null,
        initialLocation: location,
      );

      if (mounted) {
        setState(() {
          _isRouterReady = true;
        });
      }

      debugPrint('✅ Router yapılandırması tamamlandı');
    } catch (e, stack) {
      ErrorHandler.logError('InitializeRouter', e, stack);
      if (mounted) {
        setState(() {
          _isRouterReady = false;
        });
      }
    }
  }

  Future<String> _handlePlatformMessage(String? message) async {
    ErrorHandler.logDebug('PlatformMessage', 'Android\'den mesaj alındı', {
      'message': message,
    });

    if (message == null) {
      return 'Mesaj boş';
    }

    try {
      if (!_isHandlingNotification) {
        _isHandlingNotification = true;
        await _processNotificationMessage(message);
        Future.delayed(const Duration(seconds: 2), () {
          _isHandlingNotification = false;
        });
      }
    } catch (e, stack) {
      ErrorHandler.logError('PlatformMessage.handle', e, stack);
      _isHandlingNotification = false;
    }

    return 'Mesaj işlendi';
  }

  Future<void> _processNotificationMessage(String message) async {
    try {
      await AppNotificationHandler.processNotificationMessage(message);
    } catch (e, stack) {
      ErrorHandler.logError('ProcessNotificationMessage', e, stack);
      await _handleNotificationError();
    }
  }

  Future<void> _handleNotificationError() async {
    try {
      ErrorHandler.logWarning(
        'NotificationError',
        'Bildirim hatası - varsayılan davranış uygulanıyor',
      );
      if (_router != null && _router!.canPop()) {
        _router!.go('/home');
      }
    } catch (e, stack) {
      ErrorHandler.logError('NotificationError.fallback', e, stack);
    }
  }

  void _checkCurrentUserAdminStatus() {
    // KRITIK: Sadece login durumundayken admin değişikliklerini işle
    if (!_isLoggedIn) {
      debugPrint('⚠️ Logged out durumda, admin kontrolü yapılmıyor');
      return;
    }

    final userData = userDataNotifier.value;
    final isAdmin = AppBootstrap.checkAdminStatus(userData);

    // Sadece durum değiştiyse güncelle ve router'ı yeniden oluştur
    if (_isCurrentUserAdmin != isAdmin) {
      debugPrint('🔄 Admin durumu değişti: $_isCurrentUserAdmin -> $isAdmin');

      _isCurrentUserAdmin = isAdmin;

      if (mounted) {
        setState(() {
          _isRouterReady = false;
        });

        // setState dışında router oluştur
        _initializeRouter();
      }
    } else {
      debugPrint(
        '⚠️ Admin durumu değişmedi ($_isCurrentUserAdmin), router güncellenmeyecek',
      );
    }
  }

  void _handleNotificationClick(String payload) async {
    try {
      debugPrint('🔄 Notification click işleniyor: $payload');
      await AppNotificationHandler.processNotificationMessage(payload);
    } catch (e, stack) {
      ErrorHandler.logError('HandleNotificationClick', e, stack);
    }
  }

  @override
  void dispose() {
    _notificationClickSubscription?.cancel();
    // ⚡ PHASE 3: authStateNotifier listener kaldırıldı, Riverpod kullanılacak
    // authStateNotifier.removeListener(_onAuthStateChanged); // DEPRECATED
    userDataNotifier.removeListener(_onUserDataChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appRouter = _router;

    // ⚡ PHASE 3: Riverpod ThemeProvider'dan tema modunu al
    final themeMode = ref.watch(themeStateProvider);

    // ⚡ PHASE 3: Riverpod AuthProvider'ı dinle
    ref.listen<bool>(authStateProvider, (previous, next) {
      _onAuthStateChanged(previous, next);
    });

    if (_isBootstrappingSession || !_isRouterReady || appRouter == null) {
      return MaterialApp(
        scaffoldMessengerKey: appScaffoldMessengerKey,
        title: 'Puantaj',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode, // ⚡ PHASE 3: Riverpod'dan gelen tema
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    // ⚡ PHASE 3: ValueListenableBuilder kaldırıldı, direkt Riverpod watch kullanılıyor
    return MaterialApp.router(
      scaffoldMessengerKey: appScaffoldMessengerKey,
      title: 'Puantaj',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode, // ⚡ PHASE 3: Riverpod'dan gelen tema
      routerConfig: appRouter,
      builder: (context, child) {
        return ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: kResponsiveBreakpoints,
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
  }
}
