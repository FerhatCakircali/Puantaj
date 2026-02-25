import 'package:flutter/material.dart';

/// Context safety mixin for StatefulWidgets.
///
/// Prevents common context-related errors by checking widget mount state
/// before performing context-dependent operations.
///
/// Critical for async operations that may complete after widget disposal.
///
/// Usage:
/// ```dart
/// class MyScreenState extends State<MyScreen> with ContextSafetyMixin {
///   Future<void> loadData() async {
///     final data = await fetchData();
///     safeSetState(() {
///       // Update state safely
///     });
///   }
/// }
/// ```
mixin ContextSafetyMixin<T extends StatefulWidget> on State<T> {
  /// Safely calls setState only if widget is still mounted
  ///
  /// Prevents "setState called after dispose" errors
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  /// Safely shows a SnackBar only if widget is still mounted
  ///
  /// Returns true if SnackBar was shown, false otherwise
  bool safeShowSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    if (!mounted) return false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return true;
  }

  /// Safely shows an error SnackBar with error styling
  bool safeShowErrorSnackBar(String message) {
    return safeShowSnackBar(
      message,
      backgroundColor: Theme.of(context).colorScheme.error,
      duration: const Duration(seconds: 4),
    );
  }

  /// Safely shows a success SnackBar with success styling
  bool safeShowSuccessSnackBar(String message) {
    return safeShowSnackBar(
      message,
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    );
  }

  /// Safely navigates to a new route only if widget is still mounted
  ///
  /// Returns the result from the new route, or null if navigation failed
  Future<U?> safeNavigate<U>(Route<U> route) async {
    if (!mounted) return null;
    return Navigator.of(context).push(route);
  }

  /// Safely navigates to a named route only if widget is still mounted
  ///
  /// Returns the result from the new route, or null if navigation failed
  Future<U?> safeNavigateNamed<U>(String routeName, {Object? arguments}) async {
    if (!mounted) return null;
    return Navigator.of(context).pushNamed<U>(routeName, arguments: arguments);
  }

  /// Safely replaces current route with a new one
  ///
  /// Returns the result from the new route, or null if navigation failed
  Future<U?> safeNavigateReplacement<U, V>(Route<U> route, {V? result}) async {
    if (!mounted) return null;
    return Navigator.of(context).pushReplacement<U, V>(route, result: result);
  }

  /// Safely replaces current route with a named route
  ///
  /// Returns the result from the new route, or null if navigation failed
  Future<U?> safeNavigateReplacementNamed<U, V>(
    String routeName, {
    V? result,
    Object? arguments,
  }) async {
    if (!mounted) return null;
    return Navigator.of(context).pushReplacementNamed<U, V>(
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  /// Safely pops the current route only if widget is still mounted
  ///
  /// Returns true if pop was successful, false otherwise
  bool safePop<U>([U? result]) {
    if (!mounted) return false;
    Navigator.of(context).pop<U>(result);
    return true;
  }

  /// Safely shows a dialog only if widget is still mounted
  ///
  /// Returns the result from the dialog, or null if dialog couldn't be shown
  Future<U?> safeShowDialog<U>({
    required Widget Function(BuildContext) builder,
    bool barrierDismissible = true,
  }) async {
    if (!mounted) return null;
    return showDialog<U>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }
}
