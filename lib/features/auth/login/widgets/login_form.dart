import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../widgets/password_field.dart';
import '../../../../widgets/common/themed_text_field.dart';

/// Login form widget'ı - Stateless UI bileşeni
class LoginForm extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRememberMeChanged;
  final VoidCallback onSignIn;
  final VoidCallback? onRegisterPressed;
  final VoidCallback? onForgotPassword;
  final bool showRememberMe;

  const LoginForm({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.rememberMe,
    required this.isLoading,
    this.errorMessage,
    required this.onRememberMeChanged,
    required this.onSignIn,
    this.onRegisterPressed,
    this.onForgotPassword,
    this.showRememberMe = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ThemedTextField(
                controller: usernameController,
                labelText: 'Kullanıcı Adı',
                prefixIcon: Icons.person_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: passwordController,
                labelText: 'Şifre',
                autofillHints: const [AutofillHints.password],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (showRememberMe)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (_) => onRememberMeChanged(),
                  ),
                  GestureDetector(
                    onTap: onRememberMeChanged,
                    child: const Text('Beni Hatırla'),
                  ),
                ],
              ),
              TextButton(
                onPressed: onForgotPassword,
                child: const Text('Şifremi Unuttum'),
              ),
            ],
          ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text.rich(
              TextSpan(
                text: '$errorMessage ',
                style: const TextStyle(color: Colors.red),
                children: <TextSpan>[
                  if (errorMessage ==
                      'Hesabınız yönetici tarafından onaylanana kadar giriş yapamazsınız.')
                    TextSpan(
                      text:
                          'Lütfen yönetici ile iletişime geçin: ferhatcakircali@gmail.com',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launchUrl(
                            Uri(
                              scheme: 'mailto',
                              path: 'ferhatcakircali@gmail.com',
                            ),
                          );
                        },
                    ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSignIn,
            style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login),
                const SizedBox(width: 12),
                const Flexible(
                  child: Text(
                    'Giriş Yap',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (onRegisterPressed != null)
          TextButton(
            onPressed: onRegisterPressed,
            child: const Text('Hesabınız yok mu? Kayıt Ol'),
          ),
      ],
    );
  }
}
