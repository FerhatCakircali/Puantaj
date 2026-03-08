import '../error_logger.dart';

/// Repository'lerde tutarlı error handling sağlayan mixin
mixin BaseRepositoryMixin {
  /// Hata durumunda fallback değer döndüren wrapper
  Future<T> executeQuery<T>(
    Future<T> Function() query,
    T fallbackValue, {
    required String context,
  }) async {
    try {
      return await query();
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(context, error: e, stackTrace: stackTrace);
      return fallbackValue;
    }
  }

  /// Hata durumunda exception fırlatan wrapper
  Future<T> executeQueryWithThrow<T>(
    Future<T> Function() query, {
    required String context,
  }) async {
    try {
      return await query();
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(context, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
