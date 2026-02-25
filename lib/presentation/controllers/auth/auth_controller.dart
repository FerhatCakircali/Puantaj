import '../../../core/error/result.dart';
import '../../../domain/usecases/auth/sign_in_usecase.dart';
import '../../../domain/usecases/auth/sign_up_usecase.dart';
import '../../../domain/usecases/auth/sign_out_usecase.dart';
import '../../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../../domain/usecases/usecase.dart';
import '../base_controller.dart';
import 'auth_state.dart';

/// Kimlik doğrulama controller'ı
///
/// Auth işlemlerini yönetir ve state'i günceller.
/// Use case'leri kullanarak business logic'i delegate eder.
class AuthController extends BaseController {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  AuthState _state = AuthState.initial();

  AuthController({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  }) : _signInUseCase = signInUseCase,
       _signUpUseCase = signUpUseCase,
       _signOutUseCase = signOutUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase;

  /// Mevcut state
  AuthState get state => _state;

  /// Giriş yap
  Future<void> signIn(String username, String password) async {
    _state = _state.copyWithLoading();
    notifyListeners();

    final params = SignInParams(username: username, password: password);
    final result = await _signInUseCase.call(params);

    switch (result) {
      case Success(:final data):
        _state = _state.copyWithUser(data);
      case Failure(:final exception):
        _state = _state.copyWithError(exception.message);
    }

    notifyListeners();
  }

  /// Kayıt ol
  Future<void> signUp(String username, String password, String fullName) async {
    _state = _state.copyWithLoading();
    notifyListeners();

    final params = SignUpParams(
      username: username,
      password: password,
      fullName: fullName,
    );
    final result = await _signUpUseCase.call(params);

    switch (result) {
      case Success(:final data):
        _state = _state.copyWithUser(data);
      case Failure(:final exception):
        _state = _state.copyWithError(exception.message);
    }

    notifyListeners();
  }

  /// Çıkış yap
  Future<void> signOut() async {
    _state = _state.copyWithLoading();
    notifyListeners();

    final result = await _signOutUseCase.call(const NoParams());

    switch (result) {
      case Success():
        _state = _state.copyWithSignOut();
      case Failure(:final exception):
        _state = _state.copyWithError(exception.message);
    }

    notifyListeners();
  }

  /// Mevcut kullanıcıyı kontrol et
  Future<void> checkAuthStatus() async {
    _state = _state.copyWithLoading();
    notifyListeners();

    final result = await _getCurrentUserUseCase.call(const NoParams());

    switch (result) {
      case Success(:final data):
        if (data != null) {
          _state = _state.copyWithUser(data);
        } else {
          _state = _state.copyWithSignOut();
        }
      case Failure(:final exception):
        _state = _state.copyWithError(exception.message);
    }

    notifyListeners();
  }
}
