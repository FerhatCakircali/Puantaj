import '../../../core/error/result.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/user.dart';
import '../../repositories/i_auth_repository.dart';
import '../usecase.dart';

/// Sign in use case parameters
class SignInParams {
  final String username;
  final String password;

  const SignInParams({required this.username, required this.password});
}

/// Sign in use case
///
/// Validates credentials and authenticates user.
/// Business rules:
/// - Username and password cannot be empty
/// - Username must be at least 3 characters
/// - Password must be at least 6 characters
class SignInUseCase implements UseCase<User, SignInParams> {
  final IAuthRepository _repository;

  SignInUseCase(this._repository);

  @override
  Future<Result<User>> call(SignInParams params) async {
    // Validate username
    if (params.username.trim().isEmpty) {
      return const Failure(ValidationException('Kullanıcı adı boş olamaz'));
    }

    if (params.username.trim().length < 3) {
      return const Failure(
        ValidationException('Kullanıcı adı en az 3 karakter olmalıdır'),
      );
    }

    // Validate password
    if (params.password.isEmpty) {
      return const Failure(ValidationException('Şifre boş olamaz'));
    }

    if (params.password.length < 6) {
      return const Failure(
        ValidationException('Şifre en az 6 karakter olmalıdır'),
      );
    }

    // Call repository
    return await _repository.signIn(params.username.trim(), params.password);
  }
}
