import '../../services/auth_service.dart';

/// Auth işlemleri için base helper
abstract class BaseAuthHelper {
  final AuthService _authService;

  BaseAuthHelper(this._authService);

  /// Kullanıcı ID'sini getirir, null ise exception fırlatır
  Future<int> getUserIdOrThrow() async {
    final userId = await _authService.getUserId();
    if (userId == null) {
      throw StateError('Kullanıcı oturumu bulunamadı');
    }
    return userId;
  }

  /// Kullanıcı ID'sini getirir, null dönebilir
  Future<int?> getUserId() async {
    return await _authService.getUserId();
  }

  /// Kullanıcı ID'sini getirir, null ise default değer döner
  Future<int?> getUserIdOrDefault([int? defaultValue]) async {
    final userId = await _authService.getUserId();
    return userId ?? defaultValue;
  }

  /// Kullanıcı ID ile işlem yapar
  Future<T> executeWithUserId<T>(
    Future<T> Function(int userId) operation,
  ) async {
    final userId = await getUserIdOrThrow();
    return await operation(userId);
  }
}

/// Auth helper implementation (mixin'ler için)
class AuthHelper extends BaseAuthHelper {
  AuthHelper(super.authService);
}
