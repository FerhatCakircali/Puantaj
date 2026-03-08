import '../error_logger.dart';
import '../errors/app_exception.dart';

/// Servislerde tutarlı error handling sağlayan mixin
///
/// Tüm catch bloklarında tekrar eden kodu ortadan kaldırır
mixin ErrorHandlerMixin {
  /// Hata durumunda fallback değer döndüren wrapper
  Future<T> handleError<T>(
    Future<T> Function() operation,
    T fallbackValue, {
    required String context,
    bool shouldRethrow = false,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(context, error: e, stackTrace: stackTrace);

      if (shouldRethrow) {
        rethrow;
      }

      return fallbackValue;
    }
  }

  /// Hata durumunda exception fırlatan wrapper
  Future<T> handleErrorWithThrow<T>(
    Future<T> Function() operation, {
    required String context,
    String? userMessage,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(context, error: e, stackTrace: stackTrace);

      if (e is AppException) {
        rethrow;
      }

      throw _transformToAppException(e, userMessage);
    }
  }

  /// Sync işlemler için hata wrapper'ı
  T handleErrorSync<T>(
    T Function() operation,
    T fallbackValue, {
    required String context,
    bool shouldRethrow = false,
  }) {
    try {
      return operation();
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(context, error: e, stackTrace: stackTrace);

      if (shouldRethrow) {
        rethrow;
      }

      return fallbackValue;
    }
  }

  /// Generic exception'ı AppException'a dönüştürür
  AppException _transformToAppException(dynamic error, String? userMessage) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection')) {
      return NetworkException(
        userMessage ?? 'İnternet bağlantısı hatası',
        originalError: error,
      );
    }

    if (errorString.contains('timeout')) {
      return TimeoutException(
        userMessage ?? 'İşlem zaman aşımına uğradı',
        originalError: error,
      );
    }

    if (errorString.contains('permission') ||
        errorString.contains('unauthorized') ||
        errorString.contains('401') ||
        errorString.contains('403')) {
      return AuthorizationException(
        userMessage ?? 'Yetkilendirme hatası',
        originalError: error,
      );
    }

    if (errorString.contains('not found') || errorString.contains('404')) {
      return NotFoundException(
        userMessage ?? 'Kaynak bulunamadı',
        originalError: error,
      );
    }

    if (errorString.contains('database') || errorString.contains('sql')) {
      return DatabaseException(
        userMessage ?? 'Veritabanı hatası',
        originalError: error,
      );
    }

    return ServerException(
      userMessage ?? 'Bir hata oluştu',
      originalError: error,
    );
  }
}
