import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base state sınıfı
/// Tüm notifier state'lerinin extend edeceği base class
class BaseState {
  final bool isLoading;
  final String? errorMessage;

  const BaseState({this.isLoading = false, this.errorMessage});

  bool get hasError => errorMessage != null;

  BaseState copyWith({bool? isLoading, String? errorMessage}) {
    return BaseState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Base notifier sınıfı
/// Tüm notifier'ların extend edeceği base class
/// Riverpod Notifier kullanarak state yönetimi sağlar
abstract class BaseNotifier<T extends BaseState> extends Notifier<T> {
  /// Loading state'e geç
  void setLoading() {
    state = _updateState(isLoading: true, errorMessage: null) as T;
  }

  /// Data state'e geç (loading false, error null)
  void setData() {
    state = _updateState(isLoading: false, errorMessage: null) as T;
  }

  /// Error state'e geç
  void setError(String error) {
    state = _updateState(isLoading: false, errorMessage: error) as T;
  }

  /// Clear error
  void clearError() {
    state = _updateState(errorMessage: null) as T;
  }

  /// State güncelleme helper metodu
  /// Alt sınıflar bu metodu override etmeli
  BaseState _updateState({bool? isLoading, String? errorMessage});
}
