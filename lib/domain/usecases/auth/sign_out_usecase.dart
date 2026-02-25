import '../../../core/error/result.dart';
import '../../repositories/i_auth_repository.dart';
import '../usecase.dart';

/// Sign out use case
///
/// Clears user session and local state.
/// Business rules:
/// - Clear all cached user data
/// - Clear authentication tokens
/// - Reset application state
class SignOutUseCase implements UseCase<void, NoParams> {
  final IAuthRepository _repository;

  SignOutUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) async {
    // Call repository to sign out
    return await _repository.signOut();
  }
}
