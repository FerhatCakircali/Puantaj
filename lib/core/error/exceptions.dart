import 'result.dart';

/// Network connectivity exception
class NetworkException extends AppException {
  const NetworkException(String message, {String? code, StackTrace? stackTrace})
    : super(message, code: code, stackTrace: stackTrace);
}

/// Authentication/authorization exception
class AuthException extends AppException {
  const AuthException(String message, {String? code, StackTrace? stackTrace})
    : super(message, code: code, stackTrace: stackTrace);
}

/// Input validation exception
class ValidationException extends AppException {
  const ValidationException(
    String message, {
    String? code,
    StackTrace? stackTrace,
  }) : super(message, code: code, stackTrace: stackTrace);
}

/// Resource not found exception
class NotFoundException extends AppException {
  const NotFoundException(
    String message, {
    String? code,
    StackTrace? stackTrace,
  }) : super(message, code: code, stackTrace: stackTrace);
}

/// Server-side error exception
class ServerException extends AppException {
  const ServerException(String message, {String? code, StackTrace? stackTrace})
    : super(message, code: code, stackTrace: stackTrace);
}
