/// Uygulama genelinde kullanılan özel exception sınıfları
///
/// Single Responsibility: Sadece exception tanımlarından sorumlu
/// Open/Closed: Yeni exception tipleri eklenebilir, mevcut olanlar değişmez

/// Base exception sınıfı
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

/// Kimlik doğrulama hataları
class AuthenticationException extends AppException {
  AuthenticationException(super.message, {super.code, super.originalError});
}

/// Yetkilendirme hataları
class AuthorizationException extends AppException {
  AuthorizationException(super.message, {super.code, super.originalError});
}

/// Validasyon hataları
class ValidationException extends AppException {
  final Map<String, String> fieldErrors;

  ValidationException(super.message, this.fieldErrors, {super.code});

  @override
  String toString() {
    final buffer = StringBuffer(message);
    if (fieldErrors.isNotEmpty) {
      buffer.write('\nAlan hataları:');
      fieldErrors.forEach((key, value) {
        buffer.write('\n  $key: $value');
      });
    }
    return buffer.toString();
  }
}

/// Network hataları
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.originalError});
}

/// Veritabanı hataları
class DatabaseException extends AppException {
  DatabaseException(super.message, {super.code, super.originalError});
}

/// İzin hataları
class PermissionException extends AppException {
  PermissionException(super.message, {super.code});
}

/// Kaynak bulunamadı hataları
class NotFoundException extends AppException {
  NotFoundException(super.message, {super.code, super.originalError});
}

/// Timeout hataları
class TimeoutException extends AppException {
  TimeoutException(super.message, {super.code, super.originalError});
}

/// Sunucu hataları
class ServerException extends AppException {
  ServerException(super.message, {super.code, super.originalError});
}

/// İş mantığı hataları
class BusinessLogicException extends AppException {
  BusinessLogicException(super.message, {super.code});
}

/// Veri formatı hataları
class DataFormatException extends AppException {
  DataFormatException(super.message, {super.code, super.originalError});
}

/// Local storage hataları
class StorageException extends AppException {
  StorageException(super.message, {super.code, super.originalError});
}

/// Güvenlik hataları
class SecurityException extends AppException {
  SecurityException(super.message, {super.code, super.originalError});
}
