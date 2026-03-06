import '../../../domain/usecases/notification/get_notifications_usecase.dart';
import '../../../core/error/result.dart';
import '../base_controller.dart';
import 'home_state.dart';

/// Ana ekran controller'ı
/// Home ekranının durumunu yönetir.
class HomeController extends BaseController {
  final GetNotificationsUseCase _getNotificationsUseCase;

  HomeState _state = HomeState.initial();

  HomeController({required GetNotificationsUseCase getNotificationsUseCase})
    : _getNotificationsUseCase = getNotificationsUseCase;

  /// Mevcut state
  HomeState get state => _state;

  /// Tab seç
  void selectTab(int index) {
    _state = _state.copyWith(selectedTab: index);
    notifyListeners();
  }

  /// Bildirimleri yükle
  Future<void> loadNotifications(int userId, String userType) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final params = GetNotificationsParams(
      recipientId: userId,
      recipientType: userType,
      unreadOnly: false,
    );

    final result = await _getNotificationsUseCase.call(params);

    switch (result) {
      case Success(:final data):
        _state = _state.copyWith(notifications: data, isLoading: false);
      case Failure(:final exception):
        _state = _state.copyWith(
          errorMessage: exception.message,
          isLoading: false,
        );
    }

    notifyListeners();
  }

  /// Kullanıcı bloke durumunu kontrol et
  Future<void> checkBlockStatus(bool isBlocked) async {
    _state = _state.copyWith(isUserBlocked: isBlocked);
    notifyListeners();
  }
}
