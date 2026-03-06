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
// ignore: deprecated_member_use
import 'package:puantaj/core/user_data_notifier.dart'; // Service katmanı için gerekli
import 'package:puantaj/core/providers/theme_provider.dart';
import 'package:puantaj/core/providers/auth_provider.dart';
import 'package:puantaj/core/providers/user_data_provider.dart';
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

  // ⚠️ DEPRECATED: loadSavedThemeMode artık kullanılmıyor
  // ThemeStateProvider otomatik olarak tema yüklüyor
  // await loadSavedThemeMode(); // REMOVED

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

    // ⚡ PHASE 3: userDataNotifier → userDataProvider senkronizasyonu
    // Service katmanı hala userDataNotifier kullanıyor, UI katmanı UserDataProvider kullanıyor
    // ignore: deprecated_member_use
    userDataNotifier.addListener(_syncUserDataToProvider);

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
    }

    // Widget unmounted kontrolü
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

  // ⚡ PHASE 3: Riverpod AuthProvider listener
  void _onAuthStateChanged(bool? previous, bool next) {
    debugPrint('🔔 Auth state listener tetiklendi: $_isLoggedIn -> $next');

    // Sadece login durumu değiştiyse işlem yap
    if (_isLoggedIn != next) {
      _isLoggedIn = next;

      if (_isLoggedIn) {
        debugPrint('🔐 Auth state değişti: Giriş yapıldı');

        // Admin durumunu güncelle - UserDataProvider'dan al
        final userData = ref.read(userDataProvider);
        final isAdmin = AppBootstrap.checkAdminStatus(userData);
        _isCurrentUserAdmin = isAdmin;

        // Router'ı yeniden oluştur
        if (mounted) {
          setState(() {
            _isRouterReady = false;
          });
          _initializeRouter();
        }
      } else {
        debugPrint('🔐 Auth state değişti: Çıkış yapıldı');

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

  /// ⚡ PHASE 3: userDataNotifier → userDataProvider senkronizasyonu
  /// Service katmanı hala userDataNotifier kullanıyor, bu fonksiyon değişiklikleri
  /// UserDataProvider'a aktarıyor. UI katmanı sadece UserDataProvider kullanmalı.
  void _syncUserDataToProvider() {
    // ignore: deprecated_member_use
    final userData = userDataNotifier.value;

    // UserDataProvider'ı güncelle
    if (userData == null) {
      ref.read(userDataProvider.notifier).clearUserData();
    } else {
      ref.read(userDataProvider.notifier).setUserData(userData);
    }
  }

  void _initializeRouter({String? forceInitialLocation}) {
    try {
      debugPrint('🛣️ Router yapılandırılıyor...');

      // UserDataProvider'dan userData al
      final userData = ref.read(userDataProvider);
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
    // ⚡ PHASE 3: Tüm ValueNotifier listener'ları
    // authStateNotifier.removeListener(_onAuthStateChanged); // DEPRECATED
    // ignore: deprecated_member_use
    userDataNotifier.removeListener(_syncUserDataToProvider);
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
