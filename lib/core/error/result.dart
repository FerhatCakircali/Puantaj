/// Result type for functional error handling
///
/// Represents the outcome of an operation that can either succeed or fail.
/// This pattern forces explicit error handling and makes error cases visible in type signatures.
///
/// Usage:
/// ```dart
/// Future<Result<User>> signIn(String username, String password) async {
///   try {
///     final user = await repository.signIn(username, password);
///     return Success(user);
///   } catch (e) {
///     return Failure(AuthException('Sign in failed: $e'));
///   }
/// }
/// ```
sealed class Result<T> {
  const Result();
}

/// Represents a successful operation result
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Represents a failed operation result
class Failure<T> extends Result<T> {
  final AppException exception;
  const Failure(this.exception);
}

/// Base exception class for all application exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const AppException(this.message, {this.code, this.stackTrace});

  @override
  String toString() =>
      'AppException: $message${code != null ? ' (code: $code)' : ''}';
}
