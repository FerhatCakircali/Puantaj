/// Form validation mixin for ViewModels and Widgets.
/// Provides reusable validation logic for common input fields.
/// Follows Single Responsibility Principle by handling only validation logic.
/// Usage:
/// ```dart
/// class MyViewModel extends ChangeNotifier with ValidationMixin {
///   String? validateLoginForm(String username, String password) {
///     return validateUsername(username) ?? validatePassword(password);
///   }
/// }
/// ```
mixin ValidationMixin {
  /// Validates username field
    /// Rules:
  /// - Required (not empty)
  /// - Minimum 3 characters
  /// - Maximum 50 characters
  /// - Only alphanumeric and underscore allowed
    /// Returns error message if invalid, null if valid
  String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kullanıcı adı gereklidir';
    }

    final trimmed = value.trim();

    if (trimmed.length < 3) {
      return 'Kullanıcı adı en az 3 karakter olmalıdır';
    }

    if (trimmed.length > 50) {
      return 'Kullanıcı adı en fazla 50 karakter olabilir';
    }

    // Only alphanumeric and underscore
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(trimmed)) {
      return 'Kullanıcı adı sadece harf, rakam ve alt çizgi içerebilir';
    }

    return null;
  }

  /// Validates password field
    /// Rules:
  /// - Required (not empty)
  /// - Minimum 6 characters
    /// Returns error message if invalid, null if valid
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gereklidir';
    }

    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }

    return null;
  }

  /// Validates password confirmation field
    /// Rules:
  /// - Must match the original password
    /// Returns error message if invalid, null if valid
  String? validatePasswordConfirmation(String? password, String? confirmation) {
    if (confirmation == null || confirmation.isEmpty) {
      return 'Şifre tekrarı gereklidir';
    }

    if (password != confirmation) {
      return 'Şifreler eşleşmiyor';
    }

    return null;
  }

  /// Validates phone number field
    /// Rules:
  /// - Optional (can be empty)
  /// - If provided, must be valid Turkish phone format
  /// - Accepts formats: 5XXXXXXXXX, 05XXXXXXXXX, +905XXXXXXXXX, 905XXXXXXXXX
    /// Returns error message if invalid, null if valid
  String? validatePhone(String? value) {
    // Phone is optional
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final trimmed = value.trim();

    // Remove common separators for validation
    final cleaned = trimmed.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Turkish phone number patterns
    final patterns = [
      RegExp(r'^5\d{9}$'), // 5XXXXXXXXX
      RegExp(r'^05\d{9}$'), // 05XXXXXXXXX
      RegExp(r'^\+905\d{9}$'), // +905XXXXXXXXX
      RegExp(r'^905\d{9}$'), // 905XXXXXXXXX
    ];

    final isValid = patterns.any((pattern) => pattern.hasMatch(cleaned));

    if (!isValid) {
      return 'Geçerli bir telefon numarası giriniz';
    }

    return null;
  }

  /// Validates full name field
    /// Rules:
  /// - Required (not empty)
  /// - Minimum 2 characters
  /// - Maximum 100 characters
    /// Returns error message if invalid, null if valid
  String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ad soyad gereklidir';
    }

    final trimmed = value.trim();

    if (trimmed.length < 2) {
      return 'Ad soyad en az 2 karakter olmalıdır';
    }

    if (trimmed.length > 100) {
      return 'Ad soyad en fazla 100 karakter olabilir';
    }

    return null;
  }

  /// Validates title/position field
    /// Rules:
  /// - Optional (can be empty)
  /// - If provided, maximum 100 characters
    /// Returns error message if invalid, null if valid
  String? validateTitle(String? value) {
    // Title is optional
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final trimmed = value.trim();

    if (trimmed.length > 100) {
      return 'Ünvan en fazla 100 karakter olabilir';
    }

    return null;
  }

  /// Validates note/comment field
    /// Rules:
  /// - Optional (can be empty)
  /// - If provided, maximum 500 characters
    /// Returns error message if invalid, null if valid
  String? validateNote(String? value) {
    // Note is optional
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final trimmed = value.trim();

    if (trimmed.length > 500) {
      return 'Not en fazla 500 karakter olabilir';
    }

    return null;
  }
}
