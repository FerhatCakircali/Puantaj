import '../auth_service.dart';

/// Tüm servisler için ortak kullanıcı ID yönetimi
class BaseUserHelper {
  final AuthService _authService;

  BaseUserHelper(this._authService);

  /// Kullanıcı ID'sini getirir, null ise exception fırlatır
  Future<int> getUserIdOrThrow() async {
    final userId = await _authService.getUserId();
    if (userId == null) {
      throw StateError('Kullanıcı oturumu bulunamadı');
    }
    return userId;
  }

  /// Kullanıcı ID'sini getirir, null ise default değer döner
  Future<int?> getUserIdOrDefault([int? defaultValue]) async {
    final userId = await _authService.getUserId();
    return userId ?? defaultValue;
  }

  /// Kullanıcı ID ile işlem yapar, null ise default değer döner
  ///
  /// Kod tekrarını elimine eder:
  /// ```dart
  /// // Önce:
  /// final userId = await _userHelper.getUserIdOrDefault();
  /// if (userId == null) return [];
  /// return await _repository.getData(userId);
  ///
  /// // Sonra:
  /// return await _userHelper.executeWithUserId(
  ///   (userId) => _repository.getData(userId),
  ///   defaultValue: [],
  /// );
  /// ```
  Future<T> executeWithUserId<T>(
    Future<T> Function(int userId) operation, {
    required T defaultValue,
  }) async {
    final userId = await getUserIdOrDefault();
    if (userId == null) return defaultValue;
    return await operation(userId);
  }

  /// Kullanıcı ID ile işlem yapar, null ise exception fırlatır
  ///
  /// Kod tekrarını elimine eder:
  /// ```dart
  /// // Önce:
  /// final userId = await _userHelper.getUserIdOrThrow();
  /// return await _repository.getData(userId);
  ///
  /// // Sonra:
  /// return await _userHelper.executeWithUserIdOrThrow(
  ///   (userId) => _repository.getData(userId),
  /// );
  /// ```
  Future<T> executeWithUserIdOrThrow<T>(
    Future<T> Function(int userId) operation,
  ) async {
    final userId = await getUserIdOrThrow();
    return await operation(userId);
  }
}
