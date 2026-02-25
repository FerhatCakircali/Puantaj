import 'package:flutter/foundation.dart';

/// Base controller sınıfı
///
/// Tüm controller'ların extend edeceği base class.
/// ChangeNotifier kullanarak state yönetimi sağlar.
///
/// Kullanım:
/// ```dart
/// class MyController extends BaseController {
///   MyData? _data;
///   bool _isLoading = false;
///   String? _error;
///
///   Future<void> loadData() async {
///     setLoading();
///     try {
///       _data = await repository.getData();
///       setData();
///     } catch (e) {
///       setError(e.toString());
///     }
///   }
/// }
/// ```
abstract class BaseController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  /// Loading durumu
  bool get isLoading => _isLoading;

  /// Hata mesajı
  String? get errorMessage => _errorMessage;

  /// Loading state'e geç
  void setLoading() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  /// Data state'e geç (loading false, error null)
  void setData() {
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Error state'e geç
  void setError(String error) {
    _isLoading = false;
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
