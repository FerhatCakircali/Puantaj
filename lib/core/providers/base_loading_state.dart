/// Loading state için base mixin
/// Tüm state class'larının kullanabileceği ortak loading pattern
mixin LoadingStateMixin {
  bool get isLoading;
  String? get errorMessage;

  bool get hasError => errorMessage != null;
  bool get isIdle => !isLoading && !hasError;
}

/// Generic loading state
/// Basit loading/error state yönetimi için
class LoadingState with LoadingStateMixin {
  @override
  final bool isLoading;

  @override
  final String? errorMessage;

  const LoadingState({this.isLoading = false, this.errorMessage});

  LoadingState copyWith({bool? isLoading, String? errorMessage}) {
    return LoadingState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  /// Loading state factory
  factory LoadingState.loading() => const LoadingState(isLoading: true);

  /// Success state factory
  factory LoadingState.success() => const LoadingState(isLoading: false);

  /// Error state factory
  factory LoadingState.error(String message) =>
      LoadingState(isLoading: false, errorMessage: message);

  /// Initial state factory
  factory LoadingState.initial() => const LoadingState();
}

/// Generic data loading state
/// Data + loading/error state yönetimi için
class DataLoadingState<T> with LoadingStateMixin {
  @override
  final bool isLoading;

  @override
  final String? errorMessage;

  final T? data;

  const DataLoadingState({
    this.isLoading = false,
    this.errorMessage,
    this.data,
  });

  bool get hasData => data != null;

  DataLoadingState<T> copyWith({
    bool? isLoading,
    String? errorMessage,
    T? data,
  }) {
    return DataLoadingState<T>(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      data: data ?? this.data,
    );
  }

  /// Loading state factory
  factory DataLoadingState.loading() => const DataLoadingState(isLoading: true);

  /// Success state factory
  factory DataLoadingState.success(T data) =>
      DataLoadingState(isLoading: false, data: data);

  /// Error state factory
  factory DataLoadingState.error(String message) =>
      DataLoadingState(isLoading: false, errorMessage: message);

  /// Initial state factory
  factory DataLoadingState.initial() => const DataLoadingState();
}
