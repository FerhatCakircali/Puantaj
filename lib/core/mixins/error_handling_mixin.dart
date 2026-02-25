import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';

/// Error state management mixin for ViewModels and Orchestrators.
///
/// Provides centralized error handling with user-friendly messages.
/// Follows Single Responsibility Principle by handling only error state logic.
///
/// Usage:
/// ```dart
/// class MyViewModel extends ChangeNotifier with ErrorHandlingMixin {
///   Future<void> fetchData() async {
///     try {
///       // Your operation
///     } catch (e, stackTrace) {
///       handleError(e, stackTrace);
///     }
///   }
/// }
/// ```
mixin ErrorHandlingMixin {
  String? _errorMessage;

  /// Current error message (null if no error)
  String? get errorMessage => _errorMessage;

  /// Whether there is an active error
  bool get hasError => _errorMessage != null;

  /// Sets the error message
  ///
  /// Should be called by subclass to trigger UI updates
  void notifyError();

  /// Sets an error message and notifies listeners
  void setError(String message) {
    _errorMessage = message;
    notifyError();
  }

  /// Clears the current error and notifies listeners
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyError();
    }
  }

  /// Handles an exception and converts it to a user-friendly error message
  ///
  /// Automatically converts AppException types to their messages.
  /// For unknown exceptions, provides a generic error message.
  ///
  /// Optionally logs the error with stack trace for debugging.
  void handleError(Object error, [StackTrace? stackTrace]) {
    String message;

    if (error is AppException) {
      message = error.message;
    } else if (error is Exception) {
      message = error.toString().replaceFirst('Exception: ', '');
    } else {
      message = 'Beklenmeyen bir hata oluştu';
    }

    // Log error for debugging (in production, send to error tracking service)
    _logError(error, stackTrace);

    setError(message);
  }

  /// Protected method to update internal error state
  ///
  /// Subclasses should call this from their notifyError implementation
  void updateErrorState(String? message) {
    _errorMessage = message;
  }

  /// Logs error for debugging purposes
  void _logError(Object error, StackTrace? stackTrace) {
    // Only log in debug mode
    // In production, send to error tracking service (e.g., Sentry, Firebase Crashlytics)
    if (kDebugMode) {
      debugPrint('Error: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }
}
