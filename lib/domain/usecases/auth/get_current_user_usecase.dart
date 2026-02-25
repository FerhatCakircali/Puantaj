import '../../../core/error/result.dart';
import '../../entities/user.dart';
import '../../repositories/i_auth_repository.dart';
import '../usecase.dart';

/// Get current user use case
///
/// Retrieves currently authenticated user from session.
/// Returns null if no user is authenticated.
class GetCurrentUserUseCase implements UseCase<User?, NoParams> {
  final IAuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  @override
  Future<Result<User?>> call(NoParams params) async {
    // Call repository to get current user
    return await _repository.getCurrentUser();
  }
}
