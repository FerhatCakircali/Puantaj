import 'dart:async';
import '../../../../services/validation_service.dart';
import '../../../../core/di/service_locator.dart';

/// Profil düzenleme controller'ı
///
/// Validation ve debounce mantığını yönetir
class ProfileEditController {
  final ValidationService _validationService = getIt<ValidationService>();
  final int? userId;
  final int? workerId;
  final String initialUsername;
  final String? initialEmail;

  Timer? _usernameDebounce;
  Timer? _emailDebounce;

  String? usernameError;
  String? emailError;

  ProfileEditController({
    this.userId,
    this.workerId,
    required this.initialUsername,
    this.initialEmail,
  });

  /// Username validation
  Future<String?> validateUsername(String username) async {
    _usernameDebounce?.cancel();

    if (username.isEmpty) {
      return 'Kullanıcı adı gerekli';
    }

    final formatError = _validationService.validateUsernameFormat(username);
    if (formatError != null) {
      return formatError;
    }

    if (username.toLowerCase() == initialUsername.toLowerCase()) {
      return null;
    }

    final completer = Completer<String?>();

    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      final availabilityError = await _validationService
          .checkUsernameAvailability(
            username,
            excludeUserId: userId,
            excludeWorkerId: workerId,
          );
      completer.complete(availabilityError);
    });

    return completer.future;
  }

  /// Email validation
  Future<String?> validateEmail(String email, {bool isRequired = true}) async {
    _emailDebounce?.cancel();

    if (email.isEmpty) {
      return isRequired ? 'E-posta adresi gerekli' : null;
    }

    final formatError = _validationService.validateEmailFormat(email);
    if (formatError != null) {
      return formatError;
    }

    if (email.toLowerCase() == (initialEmail ?? '').toLowerCase()) {
      return null;
    }

    final completer = Completer<String?>();

    _emailDebounce = Timer(const Duration(milliseconds: 500), () async {
      final availabilityError = await _validationService.checkEmailAvailability(
        email,
        excludeUserId: userId,
        excludeWorkerId: workerId,
      );
      completer.complete(availabilityError);
    });

    return completer.future;
  }

  /// Dispose timers
  void dispose() {
    _usernameDebounce?.cancel();
    _emailDebounce?.cancel();
  }
}
