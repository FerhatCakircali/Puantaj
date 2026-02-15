import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:puantaj/screens/home_screen.dart';
import 'package:puantaj/screens/login_screen.dart';
import 'package:puantaj/screens/register_screen.dart';
import 'package:puantaj/screens/report_screen.dart';
import 'package:puantaj/screens/admin_panel_screen.dart';
import 'package:puantaj/screens/notification_settings_screen.dart';
import 'package:puantaj/screens/attendance_screen.dart';
import 'package:puantaj/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRouter {
  final bool isLoggedIn;
  final GlobalKey<NavigatorState>? navigatorKey;

  AppRouter({required this.isLoggedIn, this.navigatorKey});

  GoRouter get config => GoRouter(
    initialLocation: isLoggedIn ? '/home' : '/login',
    navigatorKey: navigatorKey,
    routes: [
      GoRoute(path: '/login', builder: (context, _) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, _) => const RegisterScreen(),
      ),
      GoRoute(path: '/home', builder: (context, _) => const HomeScreen()),
      GoRoute(path: '/report', builder: (context, _) => const ReportScreen()),
      GoRoute(
        path: '/admin',
        builder: (context, _) => const AdminPanelScreen(),
      ),
      GoRoute(
        path: '/attendance',
        builder: (context, _) => const AttendanceScreen(),
      ),
    ],
    redirect: (context, state) async {
      final location = state.uri.toString();
      final loggingIn = location == '/login' || location == '/register';

      // Çıkış yapıldığında veya giriş yapılmadığında login sayfasına yönlendir
      if (!isLoggedIn && !loggingIn) {
        return '/login';
      }

      // Giriş yapmış kullanıcıyı uygun sayfaya yönlendir
      if (isLoggedIn) {
        // Login veya register sayfasındaysa
        if (loggingIn) {
          // Bildirimden açılma durumunu kontrol et
          try {
            final prefs = await SharedPreferences.getInstance();
            final launchedFromNotification =
                prefs.getBool('launched_from_notification') ?? false;

            // Eğer bildirimden açıldıysa ve giriş yapılmışsa, ana sayfaya yönlendir
            if (launchedFromNotification) {
              print(
                'AppRouter: Uygulama bildirimden başlatıldı, ana sayfaya yönlendiriliyor',
              );
              return '/home';
            }
          } catch (e) {
            print('AppRouter: Bildirim durumu kontrolünde hata: $e');
          }

          // Normal akış - admin kontrolü yap
          final isAdmin = await AuthService().isAdmin();
          return isAdmin ? '/admin' : '/home';
        }

        // Admin kullanıcısı admin sayfası dışında bir yerdeyse
        final isAdmin = await AuthService().isAdmin();
        if (isAdmin && location != '/admin') {
          return '/admin';
        }

        // Normal kullanıcı admin sayfasındaysa
        if (!isAdmin && location == '/admin') {
          return '/home';
        }
      }

      return null;
    },
    debugLogDiagnostics: true, // Hata ayıklama için
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
