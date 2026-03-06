import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AuthStateNotifier - Kimlik doğrulama durumunu yöneten Notifier.
/// Bu sınıf, kullanıcının giriş/çıkış durumunu yönetir ve
/// uygulama genelinde auth state değişikliklerini bildirir.
/// **Özellikler:**
/// - Login/logout işlemleri
/// - Auth state değişikliklerini dinleme
/// - Mevcut authStateNotifier ile paralel çalışır (backward compatibility)
/// **Kullanım:**
/// ```dart
/// // Auth state'i okuma
/// final isAuthenticated = ref.watch(authStateProvider);
/// // Login işlemi
/// ref.read(authStateProvider.notifier).login();
/// // Logout işlemi
/// ref.read(authStateProvider.notifier).logout();
/// ```
/// Saat Dilimi: Europe/Istanbul (UTC+3)
class AuthStateNotifier extends Notifier<bool> {
  /// Başlangıç durumu - false (çıkış yapmış)
  @override
  bool build() {
    return false;
  }

  /// Kullanıcı giriş yaptığında çağrılır.
    /// Auth state'i true yapar ve tüm dinleyicilere bildirir.
    /// Örnek:
  /// ```dart
  /// ref.read(authStateProvider.notifier).login();
  /// ```
  void login() {
    state = true;
  }

  /// Kullanıcı çıkış yaptığında çağrılır.
    /// Auth state'i false yapar ve tüm dinleyicilere bildirir.
    /// Örnek:
  /// ```dart
  /// ref.read(authStateProvider.notifier).logout();
  /// ```
  void logout() {
    state = false;
  }

  /// Auth state'i manuel olarak ayarlar.
    /// Parametreler:
  /// - [isAuthenticated]: Yeni auth durumu
    /// Örnek:
  /// ```dart
  /// ref.read(authStateProvider.notifier).setState(true);
  /// ```
  void setState(bool isAuthenticated) {
    state = isAuthenticated;
  }
}

/// AuthStateProvider - Auth state'i sağlayan global provider.
/// Bu provider, uygulamanın her yerinden auth durumuna erişim sağlar.
/// **Kullanım Örnekleri:**
/// ```dart
/// // Widget içinde auth state'i dinleme
/// class MyWidget extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final isAuthenticated = ref.watch(authStateProvider);
///     return Text(isAuthenticated ? 'Giriş Yapıldı' : 'Çıkış Yapıldı');
///   }
/// }
/// // Auth state değişikliklerini dinleme
/// ref.listen<bool>(authStateProvider, (previous, next) {
///   if (next) {
///     // Giriş yapıldı
///   } else {
///     // Çıkış yapıldı
///   }
/// });
/// ```
final authStateProvider = NotifierProvider<AuthStateNotifier, bool>(() {
  return AuthStateNotifier();
});
