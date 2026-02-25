import '../../../core/error/result.dart';

/// Base use case interface
///
/// Defines contract for all use cases in the application.
/// Use cases encapsulate business logic and orchestrate data flow.
///
/// Type parameters:
/// - [Type]: Return type of the use case
/// - [Params]: Input parameters type
///
/// Usage:
/// ```dart
/// class SignInUseCase implements UseCase<User, SignInParams> {
///   @override
///   Future<Result<User>> call(SignInParams params) async {
///     // Business logic here
///   }
/// }
/// ```
abstract class UseCase<Type, Params> {
  /// Execute the use case
  ///
  /// Returns [Result<Type>] wrapping success or failure
  Future<Result<Type>> call(Params params);
}

/// No parameters class for use cases that don't require input
///
/// Usage:
/// ```dart
/// class GetCurrentUserUseCase implements UseCase<User?, NoParams> {
///   @override
///   Future<Result<User?>> call(NoParams params) async {
///     // Business logic here
///   }
/// }
/// ```
class NoParams {
  const NoParams();
}
