import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/email_service.dart';
import '../../../../widgets/password_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String token;
  final String userType;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.token,
    this.userType = 'user',
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailService = EmailService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    // Şifre uzunluk kontrolü
    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Şifre en az 6 karakter olmalıdır');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Şifreler eşleşmiyor');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final error = await _emailService.resetPasswordWithToken(
        token: widget.token,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      if (error != null) {
        setState(() => _errorMessage = error);
      } else {
        _showSuccessDialog();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false, // Back button'u devre dışı bırak
        child: AlertDialog(
          title: const Text('Başarılı'),
          content: const Text('Şifreniz başarıyla sıfırlandı.'),
          actions: [
            TextButton(
              onPressed: () {
                // Dialog'u kapat
                Navigator.of(dialogContext).pop();
                // Tüm navigation stack'i temizle ve login'e git
                if (mounted) {
                  // Tüm ekranları kapat ve login'e git
                  while (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  context.go('/login');
                }
              },
              child: const Text('Giriş Yap'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final maxWidth = isTablet ? 500.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Şifre Belirle')),
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
                          _buildHeader(context),
                          const SizedBox(height: 24),
                          _buildDescription(),
                          const SizedBox(height: 24),
                          PasswordField(
                            controller: _passwordController,
                            labelText: 'Yeni Şifre',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Şifre gerekli';
                              }
                              if (value.length < 6) {
                                return 'Şifre en az 6 karakter olmalıdır';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          PasswordField(
                            controller: _confirmPasswordController,
                            labelText: 'Yeni Şifre (Tekrar)',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Şifre tekrarı gerekli';
                              }
                              if (value.length < 6) {
                                return 'Şifre en az 6 karakter olmalıdır';
                              }
                              return null;
                            },
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 24),
                          _buildSubmitButton(),
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

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.vpn_key,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Yeni Şifre',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      children: [
        Text(
          'Yeni şifrenizi belirleyin.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Şifreniz en az 6 karakter olmalıdır.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _resetPassword,
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Şifreyi Sıfırla'),
      ),
    );
  }
}
