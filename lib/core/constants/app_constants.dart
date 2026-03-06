/// Uygulama genelinde kullanılan sabitler
/// Single Responsibility: Sadece uygulama sabitlerini tutar
class AppConstants {
  // Private constructor - utility class
  AppConstants._();

  // Uygulama bilgileri
  static const String appName = 'Yevmiye Takip';
  static const String appVersion = '2.0.0';

  // Oturum yönetimi
  static const Duration sessionDuration = Duration(days: 7);
  static const String sessionKey = 'worker_session';
  static const String userSessionKey = 'user_session';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Timeout süreleri
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);

  // Dosya boyutları
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxImageSizeBytes = 2 * 1024 * 1024; // 2MB

  // Validasyon
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 50;
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 100;

  // UI
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 2.0;

  // Animation
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Snackbar
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration errorSnackbarDuration = Duration(seconds: 5);

  // Cache
  static const Duration cacheDuration = Duration(minutes: 5);
  static const Duration longCacheDuration = Duration(hours: 1);

  // Lazy loading
  static const double scrollThreshold = 0.8; // 80% scroll için yeni veri yükle

  // Date formats
  static const String dateFormat = 'dd.MM.yyyy';
  static const String dateTimeFormat = 'dd.MM.yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
  static const String monthYearFormat = 'MMMM yyyy';

  // Error messages
  static const String genericErrorMessage =
      'Bir hata oluştu. Lütfen tekrar deneyin.';
  static const String networkErrorMessage =
      'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.';
  static const String timeoutErrorMessage =
      'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.';
  static const String unauthorizedErrorMessage =
      'Yetkilendirme hatası. Lütfen tekrar giriş yapın.';
  static const String notFoundErrorMessage = 'İstenen kaynak bulunamadı.';

  // Success messages
  static const String loginSuccessMessage = 'Giriş başarılı';
  static const String logoutSuccessMessage = 'Çıkış yapıldı';
  static const String saveSuccessMessage = 'Kaydedildi';
  static const String updateSuccessMessage = 'Güncellendi';
  static const String deleteSuccessMessage = 'Silindi';
}
