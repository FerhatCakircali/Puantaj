/// Loading state management mixin for ViewModels and Orchestrators.
///
/// Provides a clean way to manage loading states with automatic state updates.
/// Follows Single Responsibility Principle by handling only loading state logic.
///
/// Usage:
/// ```dart
/// class MyViewModel extends ChangeNotifier with LoadingMixin {
///   Future<void> fetchData() async {
///     await withLoading(() async {
///       // Your async operation here
///     });
///   }
/// }
/// ```
mixin LoadingMixin {
  bool _isLoading = false;

  /// Current loading state
  bool get isLoading => _isLoading;

  /// Sets the loading state
  ///
  /// Should be called by subclass to trigger UI updates
  void setLoading(bool value);

  /// Executes an async operation with automatic loading state management
  ///
  /// Sets loading to true before execution, false after completion.
  /// Ensures loading is set to false even if operation throws.
  ///
  /// Returns the result of the operation.
  Future<T> withLoading<T>(Future<T> Function() operation) async {
    setLoading(true);
    try {
      return await operation();
    } finally {
      setLoading(false);
    }
  }

  /// Protected method to update internal loading state
  ///
  /// Subclasses should call this from their setLoading implementation
  void updateLoadingState(bool value) {
    _isLoading = value;
  }
}
