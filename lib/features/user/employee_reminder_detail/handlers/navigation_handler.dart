import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigasyon işlemlerini yöneten sınıf
class NavigationHandler {
  /// Geri dönüş navigasyonu yapar
  static Future<void> navigateBack(BuildContext context) async {
    if (!context.mounted) return;

    // Kısa gecikme sonrası navigasyon
    await Future.delayed(const Duration(milliseconds: 300));

    if (!context.mounted) return;

    // Güvenli navigasyon: pop ile geri dön
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // Eğer pop yapılamazsa, home'a git
      context.go('/home');
    }
  }

  /// Drawer'dan seçilen tab'a navigasyon yapar
  static Future<void> navigateToTab(BuildContext context, int tabIndex) async {
    if (!context.mounted) return;

    // Drawer'ı kapat
    Navigator.pop(context);

    // Kısa gecikme sonrası navigasyon (drawer animasyonu için)
    await Future.delayed(const Duration(milliseconds: 200));

    if (!context.mounted) return;

    // Mevcut ekranı kapat ve home'a git
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    if (!context.mounted) return;
    context.go('/home', extra: {'initialTab': tabIndex});
  }

  /// Logout sonrası login ekranına navigasyon yapar
  static void navigateToLogin(BuildContext context) {
    if (!context.mounted) return;
    context.go('/login');
  }
}
