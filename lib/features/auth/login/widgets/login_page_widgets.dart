import 'package:flutter/material.dart';

import '../../../user/register/screens/register_screen.dart';
import '../../password_reset/screens/forgot_password_screen.dart';
import 'index.dart';

/// Admin login page widget
class AdminLoginPage extends StatelessWidget {
  final double maxWidth;
  final bool isTablet;
  final bool isFromAccountSwitch;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRememberMeChanged;
  final VoidCallback onSignIn;

  const AdminLoginPage({
    super.key,
    required this.maxWidth,
    required this.isTablet,
    required this.isFromAccountSwitch,
    required this.usernameController,
    required this.passwordController,
    required this.rememberMe,
    required this.isLoading,
    this.errorMessage,
    required this.onRememberMeChanged,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
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
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LoginHeader(isFromAccountSwitch: isFromAccountSwitch),
                    const SizedBox(height: 24),
                    LoginForm(
                      usernameController: usernameController,
                      passwordController: passwordController,
                      rememberMe: rememberMe,
                      isLoading: isLoading,
                      errorMessage: errorMessage,
                      onRememberMeChanged: onRememberMeChanged,
                      onSignIn: onSignIn,
                      onForgotPassword: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ForgotPasswordScreen(userType: 'user'),
                          ),
                        );
                      },
                      onRegisterPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Worker login page widget
class WorkerLoginPage extends StatelessWidget {
  final double maxWidth;
  final bool isTablet;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRememberMeChanged;
  final VoidCallback onSignIn;

  const WorkerLoginPage({
    super.key,
    required this.maxWidth,
    required this.isTablet,
    required this.usernameController,
    required this.passwordController,
    required this.rememberMe,
    required this.isLoading,
    this.errorMessage,
    required this.onRememberMeChanged,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
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
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WorkerLoginHeader(),
                    const SizedBox(height: 24),
                    LoginForm(
                      usernameController: usernameController,
                      passwordController: passwordController,
                      rememberMe: rememberMe,
                      isLoading: isLoading,
                      errorMessage: errorMessage,
                      onRememberMeChanged: onRememberMeChanged,
                      onSignIn: onSignIn,
                      onForgotPassword: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ForgotPasswordScreen(userType: 'worker'),
                          ),
                        );
                      },
                      showRememberMe: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Worker login header
class WorkerLoginHeader extends StatelessWidget {
  const WorkerLoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.work_outline,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Çalışan Girişi',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Page indicator for tab navigation
class PageIndicator extends StatelessWidget {
  final int index;
  final int currentPage;
  final String label;
  final ThemeData theme;
  final VoidCallback onTap;

  const PageIndicator({
    super.key,
    required this.index,
    required this.currentPage,
    required this.label,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentPage == index;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 3,
            width: isActive ? 60 : 0,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
