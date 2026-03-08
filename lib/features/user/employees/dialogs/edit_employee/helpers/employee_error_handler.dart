import 'package:flutter/material.dart';

/// Çalışan işlemleri hata yönetim yardımcı sınıfı
class EmployeeErrorHandler {
  /// Hata mesajını gösterir ve gerekirse login sayfasına yönlendirir
  ///
  /// Oturum hatası varsa kullanıcıyı login sayfasına yönlendirir.
  /// Diğer hatalar için genel hata mesajı gösterir.
  static void handleError(
    BuildContext context,
    Object error, {
    VoidCallback? onSessionExpired,
  }) {
    if (!context.mounted) return;

    debugPrint('EditEmployeeDialog: Güncelleme hatası: $error');

    final errorMessage = error.toString();
    if (errorMessage.contains('Kullanıcı oturumu bulunamadı')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Oturumunuz sonlanmış. Lütfen tekrar giriş yapın.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });

      onSessionExpired?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İşlem sırasında bir hata oluştu: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
