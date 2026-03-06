import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UserDataNotifier - Kullanıcı verilerini yöneten Notifier.
///
/// Bu sınıf, oturum açmış kullanıcının verilerini (isim, email, role vb.)
/// yönetir ve uygulama genelinde erişim sağlar.
///
/// **Özellikler:**
/// - Kullanıcı verilerini saklama
/// - Admin kontrolü (isAdmin getter)
/// - Veri temizleme (logout)
/// - Null-safe veri erişimi
/// - Mevcut userDataNotifier ile paralel çalışır (backward compatibility)
///
/// **Kullanım:**
/// ```dart
/// // Kullanıcı verilerini okuma
/// final userData = ref.watch(userDataProvider);
///
/// // Admin kontrolü
/// final isAdmin = ref.read(userDataProvider.notifier).isAdmin;
///
/// // Kullanıcı verilerini ayarlama
/// ref.read(userDataProvider.notifier).setUserData(userData);
///
/// // Veri temizleme
/// ref.read(userDataProvider.notifier).clearUserData();
/// ```
///
/// Saat Dilimi: Europe/Istanbul (UTC+3)
class UserDataNotifier extends Notifier<Map<String, dynamic>?> {
  /// Başlangıç durumu - null (oturum açılmamış)
  @override
  Map<String, dynamic>? build() {
    return null;
  }

  /// Kullanıcı verilerini ayarlar.
  ///
  /// Login işlemi sonrasında kullanıcı bilgilerini saklamak için kullanılır.
  ///
  /// Parametreler:
  /// - [userData]: Kullanıcı verileri (Map formatında)
  ///
  /// Örnek:
  /// ```dart
  /// final userData = {
  ///   'id': '123',
  ///   'email': 'user@example.com',
  ///   'full_name': 'Ahmet Yılmaz',
  ///   'role': 'admin',
  /// };
  /// ref.read(userDataProvider.notifier).setUserData(userData);
  /// ```
  void setUserData(Map<String, dynamic> userData) {
    state = userData;
  }

  /// Kullanıcı verilerini temizler.
  ///
  /// Logout işlemi sırasında kullanılır. State'i null yapar.
  ///
  /// Örnek:
  /// ```dart
  /// ref.read(userDataProvider.notifier).clearUserData();
  /// ```
  void clearUserData() {
    state = null;
  }

  /// Kullanıcının admin olup olmadığını kontrol eder.
  ///
  /// Returns:
  /// - true: Kullanıcı admin
  /// - false: Kullanıcı admin değil veya oturum açılmamış
  ///
  /// Örnek:
  /// ```dart
  /// final isAdmin = ref.read(userDataProvider.notifier).isAdmin;
  /// if (isAdmin) {
  ///   // Admin panelini göster
  /// }
  /// ```
  bool get isAdmin {
    if (state == null) return false;

    final role = state!['role'] as String?;
    return role == 'admin';
  }

  /// Kullanıcının ID'sini döndürür.
  ///
  /// Returns:
  /// - String: Kullanıcı ID'si
  /// - null: Oturum açılmamış
  ///
  /// Örnek:
  /// ```dart
  /// final userId = ref.read(userDataProvider.notifier).userId;
  /// ```
  String? get userId {
    if (state == null) return null;
    return state!['id'] as String?;
  }

  /// Kullanıcının email adresini döndürür.
  ///
  /// Returns:
  /// - String: Email adresi
  /// - null: Oturum açılmamış veya email yok
  ///
  /// Örnek:
  /// ```dart
  /// final email = ref.read(userDataProvider.notifier).email;
  /// ```
  String? get email {
    if (state == null) return null;
    return state!['email'] as String?;
  }

  /// Kullanıcının tam adını döndürür.
  ///
  /// Returns:
  /// - String: Tam ad
  /// - null: Oturum açılmamış veya isim yok
  ///
  /// Örnek:
  /// ```dart
  /// final fullName = ref.read(userDataProvider.notifier).fullName;
  /// ```
  String? get fullName {
    if (state == null) return null;
    return state!['full_name'] as String?;
  }

  /// Kullanıcının kullanıcı adını döndürür.
  ///
  /// Returns:
  /// - String: Kullanıcı adı
  /// - null: Oturum açılmamış veya username yok
  ///
  /// Örnek:
  /// ```dart
  /// final username = ref.read(userDataProvider.notifier).username;
  /// ```
  String? get username {
    if (state == null) return null;
    return state!['username'] as String?;
  }

  /// Kullanıcının oturum açıp açmadığını kontrol eder.
  ///
  /// Returns:
  /// - true: Oturum açık
  /// - false: Oturum kapalı
  ///
  /// Örnek:
  /// ```dart
  /// final isLoggedIn = ref.read(userDataProvider.notifier).isLoggedIn;
  /// ```
  bool get isLoggedIn {
    return state != null;
  }

  /// Belirli bir alanın değerini döndürür.
  ///
  /// Parametreler:
  /// - [key]: Alan adı
  ///
  /// Returns:
  /// - dynamic: Alan değeri
  /// - null: Alan yok veya oturum kapalı
  ///
  /// Örnek:
  /// ```dart
  /// final role = ref.read(userDataProvider.notifier).getField('role');
  /// ```
  dynamic getField(String key) {
    if (state == null) return null;
    return state![key];
  }
}

/// UserDataProvider - Kullanıcı verilerini sağlayan global provider.
///
/// Bu provider, uygulamanın her yerinden kullanıcı verilerine erişim sağlar.
///
/// **Kullanım Örnekleri:**
/// ```dart
/// // Widget içinde kullanıcı verilerini dinleme
/// class ProfileWidget extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final userData = ref.watch(userDataProvider);
///     if (userData == null) {
///       return Text('Oturum açılmamış');
///     }
///     return Text('Hoş geldin, ${userData['full_name']}');
///   }
/// }
///
/// // Admin kontrolü
/// final isAdmin = ref.read(userDataProvider.notifier).isAdmin;
/// if (isAdmin) {
///   // Admin panelini göster
/// }
///
/// // Kullanıcı verilerini ayarlama (login sonrası)
/// ref.read(userDataProvider.notifier).setUserData({
///   'id': '123',
///   'email': 'user@example.com',
///   'full_name': 'Ahmet Yılmaz',
///   'role': 'admin',
/// });
///
/// // Veri temizleme (logout)
/// ref.read(userDataProvider.notifier).clearUserData();
/// ```
final userDataProvider =
    NotifierProvider<UserDataNotifier, Map<String, dynamic>?>(() {
      return UserDataNotifier();
    });
