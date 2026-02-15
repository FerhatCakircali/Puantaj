import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../widgets/password_field.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  bool _isLoading = false;
  String? _usernameError;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }

  void _validateUsername(String value) async {
    if (value.isEmpty) {
      setState(() => _usernameError = 'Kullanıcı adı gerekli');
      return;
    }

    final validUsernameRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!validUsernameRegex.hasMatch(value)) {
      setState(
        () => _usernameError =
            'Sadece İngilizce harfler (A-Z) ve sayılar (0-9) kullanılabilir',
      );
      return;
    }

    // Kullanıcı adı kullanılabilirlik kontrolü
    final availabilityError = await AuthService().checkUsernameAvailability(
      value,
    );
    if (availabilityError != null) {
      setState(() => _usernameError = availabilityError);
      return;
    }

    setState(() => _usernameError = null);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final validUsernameRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!validUsernameRegex.hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kullanıcı adı sadece İngilizce harfler (A-Z) ve sayılardan (0-9) oluşmalıdır.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final error = await AuthService().register(
        username,
        _passwordController.text,
        _firstNameController.text,
        _lastNameController.text,
        _jobTitleController.text,
      );

      if (error != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      } else {
        if (!mounted) return;
        // Başarılı kayıt sonrası login ekranına yönlendir
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt başarılı! Lütfen giriş yapın.'),
            backgroundColor: Colors.green,
          ),
        );
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(prefixIcon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final maxWidth = isTablet ? 500.0 : double.infinity;

    return Scaffold(
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_add_alt_1,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Yeni Hesap Oluştur',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _usernameController,
                            decoration: _inputDecoration(
                              label: 'Kullanıcı Adı',
                              prefixIcon: Icons.person_outline,
                            ).copyWith(errorText: _usernameError),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kullanıcı adı gerekli';
                              }
                              final validUsernameRegex = RegExp(
                                r'^[a-zA-Z0-9]+$',
                              );
                              if (!validUsernameRegex.hasMatch(value)) {
                                return 'Sadece İngilizce harfler (A-Z) ve sayılar (0-9) kullanılabilir';
                              }
                              return null;
                            },
                            maxLength: 30,
                            maxLengthEnforcement: MaxLengthEnforcement.enforced,
                            onChanged: _validateUsername,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _firstNameController,
                            decoration: _inputDecoration(
                              label: 'Ad',
                              prefixIcon: Icons.person_outline,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ad gerekli';
                              }
                              return null;
                            },
                            maxLength: 30,
                            maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: _inputDecoration(
                              label: 'Soyad',
                              prefixIcon: Icons.person_outline,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Soyad gerekli';
                              }
                              return null;
                            },
                            maxLength: 30,
                            maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _jobTitleController,
                            decoration: _inputDecoration(
                              label: 'Yapılan İş',
                              prefixIcon: Icons.work_outline,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Yapılan iş bilgisi gerekli';
                              }
                              return null;
                            },
                            maxLength: 30,
                            maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          ),
                          const SizedBox(height: 16),
                          PasswordField(
                            controller: _passwordController,
                            labelText: 'Şifre',
                          ),
                          const SizedBox(height: 16),
                          PasswordField(
                            controller: _confirmPasswordController,
                            labelText: 'Şifre (Tekrar)',
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.person_add_alt_1),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      'Kayıt Ol',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
