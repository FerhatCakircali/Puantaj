import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../auth/login/screens/login_screen.dart';
import '../controllers/register_controller.dart';
import '../widgets/register_form.dart';

/// Kayıt ekranı
///
/// Yeni kullanıcı kaydı işlemlerini yönetir.
/// AGENTS.md kurallarına uygun olarak modüler yapıda tasarlanmıştır.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _controller = RegisterController();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _usernameError;
  String? _emailError;
  Timer? _usernameDebounce;
  Timer? _emailDebounce;

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _emailDebounce?.cancel();

    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _jobTitleController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _validateUsername(String value) async {
    // Debounce: 500ms bekle
    _usernameDebounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() => _usernameError = null);
      return;
    }

    final error = _controller.validateUsername(value);
    if (error != null) {
      setState(() => _usernameError = error);
      return;
    }

    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      // Kullanıcı adı kullanılabilirlik kontrolü
      final availabilityError = await _controller.checkUsernameAvailability(
        value,
      );
      if (mounted) {
        setState(() => _usernameError = availabilityError);
      }
    });
  }

  void _validateEmail(String value) async {
    // Debounce: 500ms bekle
    _emailDebounce?.cancel();

    debugPrint('🔍 RegisterScreen: Email validation başladı: $value');

    if (value.trim().isEmpty) {
      debugPrint('🔍 RegisterScreen: Email boş, hata temizlendi');
      setState(() => _emailError = null);
      return;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      debugPrint('🔍 RegisterScreen: Email format hatası');
      setState(() => _emailError = 'Geçerli bir e-posta adresi girin');
      return;
    }

    _emailDebounce = Timer(const Duration(milliseconds: 500), () async {
      debugPrint('🔍 RegisterScreen: Email kontrolü başlıyor: ${value.trim()}');
      // Email kullanılabilirlik kontrolü
      final availabilityError = await _controller.checkEmailAvailability(
        value.trim(),
      );
      debugPrint(
        '🔍 RegisterScreen: Email kontrolü sonucu: $availabilityError',
      );
      if (mounted) {
        setState(() {
          _emailError = availabilityError;
          debugPrint(
            '🔍 RegisterScreen: setState çağrıldı, _emailError: $_emailError',
          );
        });
      }
    });
  }

  Future<void> _register() async {
    // Boş alan kontrolü
    if (_usernameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _jobTitleController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      _showErrorMessage('Lütfen tüm alanları doldurun');
      return;
    }

    // Real-time validation hatası varsa kayıt yapma
    if (_usernameError != null || _emailError != null) {
      _showErrorMessage('Lütfen hataları düzeltin');
      return;
    }

    // Şifre eşleşme kontrolü
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorMessage('Şifreler eşleşmiyor');
      return;
    }

    final username = _usernameController.text.trim();
    final usernameValidation = _controller.validateUsername(username);

    if (usernameValidation != null) {
      _showErrorMessage(usernameValidation);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final error = await _controller.register(
        username: username,
        password: _passwordController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        jobTitle: _jobTitleController.text,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
      );

      if (error != null) {
        if (!mounted) return;
        _showErrorMessage(error);
      } else {
        if (!mounted) return;
        _showSuccessMessage();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kayıt başarılı! Lütfen giriş yapın.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final maxWidth = isTablet ? 500.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 16,
                  vertical: isTablet ? 32 : 16,
                ),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: RegisterForm(
                      formKey: _formKey,
                      usernameController: _usernameController,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      firstNameController: _firstNameController,
                      lastNameController: _lastNameController,
                      jobTitleController: _jobTitleController,
                      emailController: _emailController,
                      usernameError: _usernameError,
                      emailError: _emailError,
                      onUsernameChanged: _validateUsername,
                      onEmailChanged: _validateEmail,
                      onSubmit: _register,
                      isLoading: _isLoading,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
