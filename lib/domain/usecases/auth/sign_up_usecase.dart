import '../../../core/error/result.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/user.dart';
import '../../repositories/i_auth_repository.dart';
import '../usecase.dart';

/// Sign up use case parameters
class SignUpParams {
  final String username;
  final String password;
  final String fullName;

  const SignUpParams({
    required this.username,
    required this.password,
    required this.fullName,
  });
}

/// Sign up use case
///
/// Validates input and creates new user account.
/// Business rules:
/// - Username must be unique
/// - Username must be at least 3 characters
/// - Password must be at least 6 characters
/// - Full name cannot be empty
class SignUpUseCase implements UseCase<User, SignUpParams> {
  final IAuthRepository _repository;

  SignUpUseCase(this._repository);

  @override
  Future<Result<User>> call(SignUpParams params) async {
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

    // Validate full name
    if (params.fullName.trim().isEmpty) {
      return const Failure(ValidationException('Ad soyad boş olamaz'));
    }

    // Call repository
    return await _repository.signUp(
      username: params.username.trim(),
      password: params.password,
      fullName: params.fullName.trim(),
    );
  }
}
