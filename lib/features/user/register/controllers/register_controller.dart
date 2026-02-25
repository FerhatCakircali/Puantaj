import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';

/// Kayıt ekranı iş mantığı kontrolcüsü
class RegisterController {
  final AuthService _authService = AuthService();

  /// Kullanıcı adı geçerliliğini kontrol eder
  String? validateUsername(String value) {
    if (value.isEmpty) {
      return 'Kullanıcı adı gerekli';
    }

    if (value.length < 3) {
      return 'Kullanıcı adı en az 3 karakter olmalıdır';
    }

    final validUsernameRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!validUsernameRegex.hasMatch(value)) {
      return 'Sadece İngilizce harfler (A-Z) ve sayılar (0-9) kullanılabilir';
    }

    return null;
  }

  /// Kullanıcı adı kullanılabilirliğini kontrol eder
  Future<String?> checkUsernameAvailability(String username) async {
    return await _authService.checkUsernameAvailability(username);
  }

  /// Kayıt işlemini gerçekleştirir
  Future<String?> register({
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String jobTitle,
    String? email,
  }) async {
    try {
      return await _authService.register(
        username,
        password,
        firstName,
        lastName,
        jobTitle,
        email: email,
      );
    } catch (e) {
      debugPrint('❌ Kayıt hatası: $e');
      return 'Kayıt sırasında bir hata oluştu';
    }
  }
}
