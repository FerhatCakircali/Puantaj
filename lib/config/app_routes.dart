import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:puantaj/features/worker/home/screens/worker_home_screen.dart';
import 'package:puantaj/features/worker/profile/screens/worker_profile_screen.dart';
import 'package:puantaj/features/admin/panel/screens/admin_panel_screen.dart';
import 'package:puantaj/features/user/employee_reminder_detail/screens/employee_reminder_detail_screen.dart';
import 'package:puantaj/features/user/home/screens/home_screen.dart';
import 'package:puantaj/features/auth/login/screens/login_screen.dart';
import 'package:puantaj/features/user/notification_settings/screens/notification_settings_screen.dart';
import 'package:puantaj/features/user/register/screens/register_screen.dart';
import 'package:puantaj/features/user/reports/screens/report_screen.dart';

/// Uygulama yönlendirme yapılandırması
/// Tüm rota tanımlarını ve navigasyon mantığını merkezileştirir
class AppRoutes {
  /// Yapılandırılmış GoRouter örneği oluştur
  ///
  /// Parametreler:
  /// - [isLoggedIn]: Mevcut kimlik doğrulama durumu
  /// - [isCurrentUserAdmin]: Mevcut kullanıcının admin yetkisi olup olmadığı
  /// - [navigatorKey]: Navigasyon yönetimi için navigator anahtarı
  /// - [initialLocation]: Başlangıç rotası (varsayılan: '/home')
  static GoRouter createRouter({
    required bool isLoggedIn,
    required bool isCurrentUserAdmin,
    GlobalKey<NavigatorState>? navigatorKey,
    String initialLocation = '/home',
  }) {
    debugPrint(
      '🛣️ AppRoutes: Router oluşturuluyor (isLoggedIn: $isLoggedIn, isAdmin: $isCurrentUserAdmin, initialLocation: $initialLocation)',
    );

    return GoRouter(
      initialLocation: initialLocation,
      navigatorKey: isLoggedIn ? navigatorKey : null,
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
          builder: (context, state) {
            // extra parametresinden tab bilgisini al
            final extra = state.extra as Map<String, dynamic>?;
            final tabIndex = extra?['tab'] as int?;

            return HomeScreen(initialTab: tabIndex);
          },
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
          path: '/notification_settings',
          builder: (context, state) => const NotificationSettingsScreen(),
        ),

        GoRoute(
          path: '/employee_reminder_detail',
          builder: (context, state) {
            // extra parametresinden reminder_id bilgisini al
            final extra = state.extra as Map<String, dynamic>?;
            final reminderId = extra?['reminder_id'] as int?;

            return EmployeeReminderDetailScreen(reminderId: reminderId);
          },
        ),
        // Çalışan paneli route'ları
        GoRoute(
          path: '/worker/login',
          builder: (context, state) =>
              const LoginScreen(), // Ana login ekranına yönlendir
        ),
        GoRoute(
          path: '/worker/home',
          builder: (context, state) {
            // extra parametresinden tab bilgisini al
            final extra = state.extra as Map<String, dynamic>?;
            final tabIndex = extra?['tab'] as int?;

            return WorkerHomeScreen(initialTab: tabIndex);
          },
        ),
        // Geriye dönük uyumluluk için dashboard route'u
        GoRoute(
          path: '/worker/dashboard',
          redirect: (context, state) => '/worker/home',
        ),
        GoRoute(
          path: '/worker/profile',
          builder: (context, state) => const WorkerProfileScreen(),
        ),
      ],
      redirect: (context, state) async {
        final location = state.uri.toString();

        // Çalışan paneli route'ları için redirect yapma (TAMAMEN BYPASS)
        if (location.startsWith('/worker')) {
          debugPrint('🛣️ AppRoutes: Worker route bypass - $location');
          return null;
        }

        final loggingIn =
            location.startsWith('/login') || location.startsWith('/register');

        debugPrint(
          '🛣️ AppRoutes: Yönlendirme kontrolü - konum: $location, isLoggedIn: $isLoggedIn, isAdmin: $isCurrentUserAdmin',
        );

        // Kimlik doğrulaması yoksa login'e yönlendir
        if (!isLoggedIn && !loggingIn) {
          debugPrint(
            '🛣️ AppRoutes: Giriş yapılmamış, /login\'e yönlendiriliyor',
          );
          return '/login';
        }

        // Giriş yapmış kullanıcıları login/register sayfalarından uzaklaştır
        if (isLoggedIn && loggingIn) {
          final target = isCurrentUserAdmin ? '/admin' : '/home';
          debugPrint(
            '🛣️ AppRoutes: Giriş yapmış kullanıcı login sayfasında, $target\'a yönlendiriliyor',
          );
          return target;
        }

        // Kök dizini uygun ana sayfaya yönlendir
        if (isLoggedIn && location == '/') {
          final target = isCurrentUserAdmin ? '/admin' : '/home';
          debugPrint('🛣️ AppRoutes: Kök dizin yönlendirmesi $target\'a');
          return target;
        }

        // Admin/kullanıcı erişim kontrolü
        if (isLoggedIn) {
          if (isCurrentUserAdmin &&
              !location.startsWith('/admin') &&
              ![
                '/notification_settings',
                '/employee_reminder_detail',
                '/pending-requests',
              ].contains(location)) {
            debugPrint(
              '🛣️ AppRoutes: Admin kullanıcı, /admin\'e yönlendiriliyor',
            );
            return '/admin';
          }

          if (!isCurrentUserAdmin && location.startsWith('/admin')) {
            debugPrint(
              '🛣️ AppRoutes: Admin olmayan kullanıcı, /home\'a yönlendiriliyor',
            );
            return '/home';
          }
        }

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
  }
}
