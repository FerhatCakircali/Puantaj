import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puantaj/config/index.dart';
import 'package:puantaj/core/app_bootstrap.dart';
import 'package:puantaj/core/app_globals.dart';
import 'package:puantaj/core/user_data_notifier.dart';
import 'package:puantaj/core/providers/theme_provider.dart';
import 'package:puantaj/core/providers/auth_provider.dart';
import 'package:puantaj/core/providers/user_data_provider.dart';
import 'package:puantaj/core/initialization/firebase_initializer.dart';
import 'package:puantaj/core/initialization/app_initializer.dart';
import 'package:puantaj/core/initialization/session_bootstrap_handler.dart';
import 'package:puantaj/core/initialization/router_manager.dart';
import 'package:puantaj/core/initialization/notification_message_handler.dart';
import 'package:puantaj/core/di/service_locator.dart';
import 'package:puantaj/services/notification/notification_helpers.dart';
import 'package:responsive_framework/responsive_framework.dart';

const kResponsiveBreakpoints = [
  Breakpoint(start: 0, end: 450, name: 'MOBILE'),
  Breakpoint(start: 451, end: 800, name: 'TABLET'),
  Breakpoint(start: 801, end: 1920, name: 'DESKTOP'),
  Breakpoint(start: 1921, end: double.infinity, name: '4K'),
];

void main() async {
  // Flutter binding'i ilk başlat (Firebase için gerekli)
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat
  await FirebaseInitializer.initialize();

  // Dependency Injection setup (ServiceInitializer'dan önce!)
  await setupServiceLocator();

  // Diğer initialization'lar (ServiceInitializer içinde DI kullanıyor)
  await AppInitializer.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isLoggedIn = false;
  static const String _notificationChannel = 'com.example.puantaj/notification';
  late BasicMessageChannel<String> _messageChannel;
  late NotificationMessageHandler _notificationHandler;

  GoRouter? _router;
  late GlobalKey<NavigatorState> _navigatorKey;
  bool _isRouterReady = false;
  bool _isCurrentUserAdmin = false;
  bool _isBootstrappingSession = true;

  StreamSubscription<String>? _notificationClickSubscription;

  @override
  void initState() {
    super.initState();

    _navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'appNavigator');
    _notificationHandler = NotificationMessageHandler();

    _bootstrapSession();

    _notificationClickSubscription = notificationClickStream.stream.listen(
      (payload) => _notificationHandler.handleNotificationClick(payload),
      onError: (error) =>
          debugPrint('Notification click stream hatası: $error'),
    );

    userDataNotifier.addListener(_syncUserDataToProvider);

    _messageChannel = const BasicMessageChannel<String>(
      _notificationChannel,
      StringCodec(),
    );
    _messageChannel.setMessageHandler(
      _notificationHandler.handlePlatformMessage,
    );
  }

  /// Uygulama açılışında oturum ve bildirim durumunu yönetir
  Future<void> _bootstrapSession() async {
    setState(() {
      _isRouterReady = false;
      _isBootstrappingSession = true;
    });

    final sessionData = await SessionBootstrapHandler.bootstrap();

    _isLoggedIn = sessionData['isLoggedIn'] as bool;
    _isCurrentUserAdmin = sessionData['isAdmin'] as bool;

    if (sessionData['isLoggedIn'] as bool) {
      ref.read(authStateProvider.notifier).login();
    } else {
      ref.read(authStateProvider.notifier).logout();
    }

    if (!mounted) return;

    await SessionBootstrapHandler.processInitialNotification();

    setState(() {
      _isBootstrappingSession = false;
    });

    _initializeRouter();
  }

  void _onAuthStateChanged(bool? previous, bool next) {
    if (_isLoggedIn != next) {
      _isLoggedIn = next;

      if (_isLoggedIn) {
        final userData = ref.read(userDataProvider);
        final isAdmin = AppBootstrap.checkAdminStatus(userData);
        _isCurrentUserAdmin = isAdmin;

        if (mounted) {
          setState(() {
            _isRouterReady = false;
          });
          _initializeRouter();
        }
      } else {
        _isCurrentUserAdmin = false;
        _navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'appNavigator');

        if (mounted) {
          setState(() {
            _isRouterReady = false;
          });
          _initializeRouter(forceInitialLocation: '/login');
        }
      }
    }
  }

  /// Kullanıcı verilerini service katmanından provider'a senkronize eder
  void _syncUserDataToProvider() {
    final userData = userDataNotifier.value;

    if (userData == null) {
      ref.read(userDataProvider.notifier).clearUserData();
    } else {
      ref.read(userDataProvider.notifier).setUserData(userData);
    }
  }

  void _initializeRouter({String? forceInitialLocation}) {
    try {
      final userData = ref.read(userDataProvider);

      _router = RouterManager.createRouter(
        isLoggedIn: _isLoggedIn,
        isCurrentUserAdmin: _isCurrentUserAdmin,
        userData: userData,
        navigatorKey: _isLoggedIn ? _navigatorKey : null,
        forceInitialLocation: forceInitialLocation,
      );

      if (mounted) {
        setState(() {
          _isRouterReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRouterReady = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _notificationClickSubscription?.cancel();
    userDataNotifier.removeListener(_syncUserDataToProvider);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appRouter = _router;

    final themeMode = ref.watch(themeStateProvider);

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
        themeMode: themeMode,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      scaffoldMessengerKey: appScaffoldMessengerKey,
      title: 'Puantaj',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
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
