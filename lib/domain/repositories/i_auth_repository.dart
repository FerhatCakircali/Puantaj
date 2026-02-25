import '../../core/error/result.dart';
import '../entities/user.dart';

/// Authentication repository interface
///
/// Defines contract for authentication operations.
/// Implementations handle actual authentication logic with data sources.
abstract class IAuthRepository {
  /// Sign in with username and password
  Future<Result<User>> signIn(String username, String password);

  /// Sign up new user
  Future<Result<User>> signUp({
    required String username,
    required String password,
    required String fullName,
  });

  /// Sign out current user
  Future<Result<void>> signOut();

  /// Get current authenticated user
  Future<Result<User?>> getCurrentUser();

  /// Refresh user session
  Future<Result<User>> refreshSession();

  /// Check if user is blocked
  Future<Result<bool>> isUserBlocked(int userId);
}
