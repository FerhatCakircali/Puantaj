import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth hata yönetim yardımcı sınıfı
class AuthErrorHandler {
  /// Genel hata mesajını döndürür
  static String handleError(Object error, String defaultMessage) {
    debugPrint('$defaultMessage: $error');

    if (error is PostgrestException) {
      return _handlePostgrestError(error);
    }

    return defaultMessage;
  }

  /// Postgrest hatalarını işler
  static String _handlePostgrestError(PostgrestException error) {
    switch (error.code) {
      case '23505':
        return 'Bu e-posta adresi zaten kullanılıyor.';
      case 'P0001':
        return 'Bu kullanıcı adı zaten kullanılıyor.';
      default:
        return 'İşlem sırasında bir hata oluştu.';
    }
  }

  /// Şifre değiştirme hatası
  static String passwordChangeError(Object error) {
    return handleError(error, 'Şifre değiştirilirken bir hata oluştu.');
  }

  /// Profil güncelleme hatası
  static String profileUpdateError(Object error) {
    return handleError(error, 'Profil güncellenirken bir hata oluştu.');
  }

  /// Kullanıcı adı güncelleme hatası
  static String usernameUpdateError(Object error) {
    return handleError(error, 'Kullanıcı adı güncellenirken bir hata oluştu.');
  }

  /// Kullanıcı silme hatası
  static String userDeletionError(Object error) {
    return handleError(error, 'Kullanıcı silinirken bir hata oluştu');
  }

  /// Kullanıcı güncelleme hatası
  static String userUpdateError(Object error) {
    return handleError(error, 'Kullanıcı güncellenirken bir hata oluştu');
  }

  /// Kullanıcı blok durumu güncelleme hatası
  static String blockStatusUpdateError(Object error) {
    return handleError(
      error,
      'Kullanıcı durumu güncellenirken bir hata oluştu',
    );
  }

  /// Admin yetkisi değiştirme hatası
  static String adminStatusChangeError(Object error) {
    return handleError(error, 'Admin yetkisi değiştirilirken bir hata oluştu');
  }
}
