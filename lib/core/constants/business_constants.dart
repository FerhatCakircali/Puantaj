/// İş mantığı sabitleri
/// Single Responsibility: Sadece business logic sabitlerini tutar
class BusinessConstants {
  // Private constructor - utility class
  BusinessConstants._();

  // ==================== ÇALIŞMA GÜNLERİ ====================

  /// Ayda çalışılan gün sayısı
  static const int workingDaysPerMonth = 26;

  /// Yarım gün çarpanı
  static const double halfDayMultiplier = 0.5;

  // ==================== BİLDİRİM ID'LERİ ====================

  /// Yevmiye talep bildirimleri için base ID
  static const int attendanceRequestNotificationId = 1000;

  /// Çalışan hatırlatıcıları için base ID offset
  /// Gerçek ID: baseId + workerId
  static const int workerReminderIdOffset = 1000;

  // ==================== SAYFALAMA ====================

  /// Varsayılan sayfa boyutu
  static const int defaultPageSize = 50;

  /// Maksimum sayfa boyutu
  static const int maxPageSize = 100;

  // ==================== ZAMAN AYARLARI ====================

  /// Varsayılan zaman dilimi
  static const String defaultTimezone = 'Europe/Istanbul';

  /// UTC offset (saat)
  static const int utcOffsetHours = 3;

  // ==================== PARA BİRİMİ ====================

  /// Para birimi sembolü
  static const String currencySymbol = '₺';

  /// Para birimi kodu
  static const String currencyCode = 'TRY';

  // ==================== VALIDATION ====================

  /// Minimum kullanıcı adı uzunluğu
  static const int minUsernameLength = 3;

  /// Maksimum kullanıcı adı uzunluğu
  static const int maxUsernameLength = 50;

  /// Minimum şifre uzunluğu
  static const int minPasswordLength = 6;

  /// Maksimum şifre uzunluğu
  static const int maxPasswordLength = 100;

  // ==================== CACHE ====================

  /// Cache süresi (saniye)
  static const int cacheExpirationSeconds = 3600; // 1 saat

  /// Maksimum cache boyutu (item sayısı)
  static const int maxCacheSize = 1000;

  // ==================== UI ====================

  /// Varsayılan animasyon süresi (milisaniye)
  static const int defaultAnimationDuration = 300;

  /// Debounce süresi (milisaniye)
  static const int debounceDuration = 500;

  /// Snackbar gösterim süresi (milisaniye)
  static const int snackbarDuration = 3000;
}
