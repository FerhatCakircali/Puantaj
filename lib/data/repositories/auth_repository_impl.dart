import '../../core/error/result.dart';
import '../../core/error/exceptions.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/supabase_datasource.dart';
import '../models/user_model.dart';

/// Authentication repository implementation
///
/// Implements IAuthRepository using Supabase as data source.
/// Handles authentication operations and user session management.
class AuthRepositoryImpl implements IAuthRepository {
  final SupabaseDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<Result<User>> signIn(String username, String password) async {
    try {
      // Query users table for matching credentials
      final response = await _dataSource.client
          .from('users')
          .select()
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();

      if (response == null) {
        return const Failure(AuthException('Invalid username or password'));
      }

      final userModel = UserModel.fromJson(response);
      return Success(userModel.toEntity());
    } catch (e, stackTrace) {
      return Failure(
        AuthException('Sign in failed: $e', stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Result<User>> signUp({
    required String username,
    required String password,
    required String fullName,
  }) async {
    try {
      // Check if username already exists
      final existing = await _dataSource.client
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();

      if (existing != null) {
        return const Failure(AuthException('Username already exists'));
      }

      // Insert new user
      final response = await _dataSource.insert('users', {
        'username': username,
        'password': password,
        'full_name': fullName,
        'is_admin': false,
      });

      final userModel = UserModel.fromJson(response);
      return Success(userModel.toEntity());
    } catch (e, stackTrace) {
      return Failure(
        AuthException('Sign up failed: $e', stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      // Clear any cached session data
      // In a real implementation, this might clear tokens, etc.
      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(
        AuthException('Sign out failed: $e', stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    try {
      // In a real implementation, this would check session/token
      // For now, return null (no session management yet)
      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(
        AuthException('Get current user failed: $e', stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Result<User>> refreshSession() async {
    try {
      // In a real implementation, this would refresh the session token
      return const Failure(AuthException('Session refresh not implemented'));
    } catch (e, stackTrace) {
      return Failure(
        AuthException('Refresh session failed: $e', stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Result<bool>> isUserBlocked(int userId) async {
    try {
      final response = await _dataSource.client
          .from('users')
          .select('is_blocked')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return const Failure(NotFoundException('User not found'));
      }

      final isBlocked = response['is_blocked'] as bool? ?? false;
      return Success(isBlocked);
    } catch (e, stackTrace) {
      return Failure(
        AuthException('Check user blocked failed: $e', stackTrace: stackTrace),
      );
    }
  }
}
