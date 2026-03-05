import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/email_service.dart';
import '../../../../widgets/common/themed_text_field.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String userType;

  const ForgotPasswordScreen({super.key, this.userType = 'user'});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _emailService = EmailService();

  bool _isLoading = false;
  bool _codeSent = false;
  String? _errorMessage;
  String? _sentEmail;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) return;

    // Klavyeyi hemen kapat
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final error = await _emailService.sendPasswordResetEmail(
        email: _emailController.text.trim(),
        userType: widget.userType,
      );

      if (!mounted) return;

      if (error != null) {
        setState(() => _errorMessage = error);
      } else {
        setState(() {
          _codeSent = true;
          _sentEmail = _emailController.text.trim();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Token'ı doğrula
      final error = await _emailService.verifyResetToken(
        _codeController.text.trim(),
      );

      if (!mounted) return;

      if (error != null) {
        setState(() => _errorMessage = error);
      } else {
        // Kod doğru, şifre sıfırlama ekranına geç
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              email: _sentEmail!,
              token: _codeController.text.trim(),
              userType: widget.userType,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final maxWidth = isTablet ? 500.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(title: const Text('Şifremi Unuttum')),
      resizeToAvoidBottomInset: true, // Klavye için resize
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(), // Smooth scroll
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior
                .onDrag, // Scroll ile klavye kapansın
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
                          if (!_codeSent) ...[
                            ThemedTextField(
                              controller: _emailController,
                              labelText: 'E-posta Adresi',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                          ] else ...[
                            ThemedTextField(
                              controller: _codeController,
                              labelText: 'Doğrulama Kodu',
                              prefixIcon: Icons.pin_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Kod gerekli';
                                }
                                if (value.length != 6) {
                                  return 'Kod 6 haneli olmalı';
                                }
                                return null;
                              },
                            ),
                          ],
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
          Icons.lock_reset,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Şifre Sıfırlama',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDescription() {
    if (!_codeSent) {
      return Text(
        'E-posta adresinizi girin. Size 6 haneli bir şifre sıfırlama kodu göndereceğiz.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        textAlign: TextAlign.center,
      );
    } else {
      return Column(
        children: [
          Text(
            '$_sentEmail adresine gönderilen 6 haneli kodu girin.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Kodu görmüyorsanız spam klasörünü kontrol edin.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : (_codeSent ? _verifyCode : _sendResetCode),
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
            : Text(_codeSent ? 'Kodu Doğrula' : 'Kod Gönder'),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-posta adresi gerekli';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir e-posta adresi girin';
    }

    return null;
  }
}
