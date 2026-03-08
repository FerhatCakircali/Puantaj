import 'dart:async';

/// Çalışan formu için validation mantığını yöneten sınıf
class EmployeeFormValidator {
  Timer? _usernameDebounce;
  Timer? _emailDebounce;

  String? usernameError;
  String? emailError;

  final Future<bool> Function(String) onCheckUsername;
  final Future<bool> Function(String) onCheckEmail;
  final void Function() onStateChanged;

  EmployeeFormValidator({
    required this.onCheckUsername,
    required this.onCheckEmail,
    required this.onStateChanged,
  });

  void dispose() {
    _usernameDebounce?.cancel();
    _emailDebounce?.cancel();
  }

  void validateUsername(String username) {
    _usernameDebounce?.cancel();

    if (username.isEmpty) {
      usernameError = null;
      onStateChanged();
      return;
    }

    if (username.length < 3) {
      usernameError = 'En az 3 karakter olmalı';
      onStateChanged();
      return;
    }

    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      final exists = await onCheckUsername(username.toLowerCase());
      usernameError = exists ? 'Bu kullanıcı adı zaten kullanılıyor' : null;
      onStateChanged();
    });
  }

  void validateEmail(String email) {
    _emailDebounce?.cancel();

    if (email.isEmpty) {
      emailError = null;
      onStateChanged();
      return;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      emailError = 'Geçerli bir e-posta adresi girin';
      onStateChanged();
      return;
    }

    _emailDebounce = Timer(const Duration(milliseconds: 500), () async {
      final exists = await onCheckEmail(email.toLowerCase());
      emailError = exists ? 'Bu e-posta adresi zaten kullanılıyor' : null;
      onStateChanged();
    });
  }

  String? validateForm({
    required String name,
    required String title,
    required String phone,
    required String email,
    required String username,
    required String password,
    required String passwordConfirm,
  }) {
    if (usernameError != null || emailError != null) {
      return 'Lütfen hataları düzeltin';
    }

    if (name.isEmpty ||
        title.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        passwordConfirm.isEmpty) {
      return 'Lütfen tüm alanları doldurun';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return 'Geçerli bir e-posta adresi girin';
    }

    if (username.length < 3) {
      return 'Kullanıcı adı en az 3 karakter olmalıdır';
    }

    if (password.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }

    if (password != passwordConfirm) {
      return 'Şifreler eşleşmiyor';
    }

    return null;
  }

  Future<String?> validateUniqueness({
    required String username,
    required String email,
  }) async {
    final usernameExists = await onCheckUsername(username.toLowerCase());
    if (usernameExists) {
      return 'Bu kullanıcı adı zaten kullanılıyor';
    }

    final emailExists = await onCheckEmail(email.toLowerCase());
    if (emailExists) {
      return 'Bu e-posta adresi zaten kullanılıyor';
    }

    return null;
  }
}
