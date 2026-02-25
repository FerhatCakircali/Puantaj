import 'package:flutter/material.dart';

/// Login ekranı başlık widget'ı (Icon + Title + Subtitle)
class LoginHeader extends StatelessWidget {
  final bool isFromAccountSwitch;

  const LoginHeader({super.key, this.isFromAccountSwitch = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isFromAccountSwitch
              ? Icons.account_circle_outlined
              : Icons.lock_outline,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          isFromAccountSwitch ? 'Yeni Hesap Ekle' : 'Giriş Yap',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        if (isFromAccountSwitch)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Giriş yaparak yeni bir hesap ekleyebilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
