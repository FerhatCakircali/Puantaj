import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../widgets/password_field.dart';
import 'register_form_field.dart';

/// Kayıt formu widget'ı
class RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController jobTitleController;
  final TextEditingController emailController;
  final String? usernameError;
  final ValueChanged<String> onUsernameChanged;
  final VoidCallback onSubmit;
  final bool isLoading;

  const RegisterForm({
    super.key,
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.firstNameController,
    required this.lastNameController,
    required this.jobTitleController,
    required this.emailController,
    required this.usernameError,
    required this.onUsernameChanged,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          RegisterFormField(
            controller: usernameController,
            label: 'Kullanıcı Adı',
            prefixIcon: Icons.person_outline,
            errorText: usernameError,
            onChanged: onUsernameChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
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
            },
          ),
          const SizedBox(height: 16),
          RegisterFormField(
            controller: firstNameController,
            label: 'Ad',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ad gerekli';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          RegisterFormField(
            controller: lastNameController,
            label: 'Soyad',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Soyad gerekli';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          RegisterFormField(
            controller: jobTitleController,
            label: 'Yapılan İş',
            prefixIcon: Icons.work_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Yapılan iş bilgisi gerekli';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          RegisterFormField(
            controller: emailController,
            label: 'Email Adresi',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email adresi gerekli';
              }
              final emailRegex = RegExp(
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              );
              if (!emailRegex.hasMatch(value)) {
                return 'Geçerli bir email adresi girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: passwordController,
            labelText: 'Şifre',
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
            controller: confirmPasswordController,
            labelText: 'Şifre (Tekrar)',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre tekrarı gerekli';
              }
              if (value.length < 6) {
                return 'Şifre en az 6 karakter olmalıdır';
              }
              if (value != passwordController.text) {
                return 'Şifreler eşleşmiyor';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildSubmitButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.person_add_alt_1,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Yeni Hesap Oluştur',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
                : const Icon(Icons.person_add_alt_1),
            const SizedBox(width: 12),
            const Flexible(
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
    );
  }
}
