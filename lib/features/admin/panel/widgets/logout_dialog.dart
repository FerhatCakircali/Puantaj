import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/auth_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../features/user/services/user_notification_listener_service.dart';

/// Çıkış onay dialog widget'ı
Future<void> showAdminLogoutDialog({
  required BuildContext context,
  required AuthService authService,
}) {
  return showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Çıkış Yap'),
      content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Hayır'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(dialogContext);

            try {
              await UserNotificationListenerService.instance.stopListening();
              await authService.signOut();
              if (context.mounted) {
                final container = ProviderScope.containerOf(context);
                container.read(authStateProvider.notifier).logout();
              }

              debugPrint(
                '✅ Çıkış işlemi tamamlandı, login ekranına yönlendiriliyor',
              );
            } catch (e) {
              debugPrint('Çıkış işlemi sırasında hata: $e');

              if (context.mounted) {
                context.go('/login');
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
            foregroundColor: Theme.of(dialogContext).colorScheme.onError,
          ),
          child: const Text('Evet'),
        ),
      ],
    ),
  );
}
