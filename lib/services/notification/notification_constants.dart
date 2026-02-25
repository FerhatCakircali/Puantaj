/// Bildirim sistemi için sabit değerler
library;

/// Bildirim ID'leri
///
/// Her bildirim tipi için benzersiz ID tanımlar.
/// Aynı ID'ye sahip bildirimler birbirinin üzerine yazar.
class NotificationIds {
  /// Yevmiye hatırlatıcısı için sabit ID
  ///
  /// Bu ID tüm yevmiye hatırlatıcıları için kullanılır.
  /// Günlük tekrarlanan bildirimler için aynı ID kullanılır.
  static const int attendanceReminder = 1;

  /// Yevmiye talep bildirimleri için sabit ID
  ///
  /// Bu ID tüm yevmiye talep bildirimleri için kullanılır.
  /// FCM ile anında gönderilen bildirimler için kullanılır.
  static const int attendanceRequests = 1000;

  // Çalışan hatırlatıcıları için dinamik ID kullanılır (reminderId)
  // Her çalışan hatırlatıcısı kendi benzersiz ID'sine sahiptir
}

/// Bildirim kanalları (Android)
///
/// Android bildirim kanalları için ID tanımları.
/// Her kanal farklı önem seviyesi ve ayarlara sahiptir.
class NotificationChannels {
  /// Yevmiye hatırlatıcısı kanalı
  ///
  /// Günlük yevmiye girişi hatırlatıcıları için kullanılır.
  /// Yüksek önem seviyesi, ses ve titreşim etkin.
  static const String attendanceReminder = 'attendance_reminder';

  /// Yevmiye talep bildirimleri kanalı
  ///
  /// Çalışanlar tarafından gönderilen yevmiye talepleri için kullanılır.
  /// FCM ile anında bildirim gönderilir.
  /// Yüksek önem seviyesi, ses ve titreşim etkin.
  static const String attendanceRequests = 'attendance_requests';

  /// Çalışan hatırlatıcıları kanalı
  ///
  /// Çalışanlarla ilgili hatırlatıcılar için kullanılır.
  /// (Doğum günü, izin dönüşü, vb.)
  /// Yüksek önem seviyesi, ses ve titreşim etkin.
  static const String employeeReminders = 'employee_reminders';

  /// Xiaomi cihazlar için özel yüksek önem kanalı
  ///
  /// Xiaomi cihazlarda bildirimlerin düzgün gösterilmesi için
  /// özel yapılandırılmış kanal.
  static const String xiaomiHighImportance = 'xiaomi_high_importance_channel';
}
