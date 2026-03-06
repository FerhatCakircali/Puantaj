import '../../../domain/entities/user.dart';

/// Kimlik doğrulama state'i
/// Auth ekranlarının durumunu yönetir.
class AuthState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({this.user, this.isLoading = false, this.errorMessage});

  /// Initial state
  factory AuthState.initial() => const AuthState();

  /// Loading state
  AuthState copyWithLoading() =>
      AuthState(user: user, isLoading: true, errorMessage: null);

  /// Success state
  AuthState copyWithUser(User user) =>
      AuthState(user: user, isLoading: false, errorMessage: null);

  /// Error state
  AuthState copyWithError(String error) =>
      AuthState(user: user, isLoading: false, errorMessage: error);

  /// Sign out state
  AuthState copyWithSignOut() =>
      const AuthState(user: null, isLoading: false, errorMessage: null);
}
