import 'package:flutter/material.dart';

/// Context-safe utility fonksiyonları
/// Single Responsibility: Context güvenliği sağlar
/// Material 3 standartlarına uygun helper metodlar
class ContextUtils {
  // Private constructor - utility class
  ContextUtils._();

  /// Context-safe SnackBar gösterimi
    /// [context] - BuildContext
  /// [message] - Gösterilecek mesaj
  /// [isError] - Hata mesajı mı? (varsayılan: false)
  /// [duration] - Gösterim süresi (opsiyonel)
  /// [action] - Aksiyon butonu (opsiyonel)
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration? duration,
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        duration: duration ?? const Duration(seconds: 3),
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Context-safe başarı mesajı gösterimi
    /// [context] - BuildContext
  /// [message] - Gösterilecek mesaj
  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, isError: false);
  }

  /// Context-safe hata mesajı gösterimi
    /// [context] - BuildContext
  /// [message] - Gösterilecek mesaj
  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      isError: true,
      duration: const Duration(seconds: 5),
    );
  }

  /// Context-safe dialog gösterimi
    /// [context] - BuildContext
  /// [title] - Dialog başlığı
  /// [content] - Dialog içeriği
  /// [actions] - Dialog aksiyonları
  /// Returns: Dialog sonucu
  static Future<T?> showAlertDialog<T>(
    BuildContext context, {
    required String title,
    required String content,
    List<Widget>? actions,
  }) async {
    if (!context.mounted) return null;

    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions:
            actions ??
            [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tamam'),
              ),
            ],
      ),
    );
  }

  /// Context-safe onay dialog'u
    /// [context] - BuildContext
  /// [title] - Dialog başlığı
  /// [content] - Dialog içeriği
  /// [confirmText] - Onay butonu metni (varsayılan: 'Evet')
  /// [cancelText] - İptal butonu metni (varsayılan: 'Hayır')
  /// Returns: true ise onaylandı, false ise iptal edildi
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Evet',
    String cancelText = 'Hayır',
  }) async {
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Context-safe loading dialog gösterimi
    /// [context] - BuildContext
  /// [message] - Yükleme mesajı (opsiyonel)
  static void showLoadingDialog(BuildContext context, {String? message}) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Context-safe loading dialog kapatma
    /// [context] - BuildContext
  static void hideLoadingDialog(BuildContext context) {
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  /// Context-safe navigation
    /// [context] - BuildContext
  /// [page] - Gidilecek sayfa
  /// Returns: Navigation sonucu
  static Future<T?> navigateTo<T>(BuildContext context, Widget page) async {
    if (!context.mounted) return null;

    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute(builder: (_) => page));
  }

  /// Context-safe navigation with replacement
    /// [context] - BuildContext
  /// [page] - Gidilecek sayfa
  /// Returns: Navigation sonucu
  static Future<T?> navigateAndReplace<T>(
    BuildContext context,
    Widget page,
  ) async {
    if (!context.mounted) return null;

    return Navigator.of(
      context,
    ).pushReplacement<T, void>(MaterialPageRoute(builder: (_) => page));
  }

  /// Context-safe navigation with clear stack
    /// [context] - BuildContext
  /// [page] - Gidilecek sayfa
  /// Returns: Navigation sonucu
  static Future<T?> navigateAndClearStack<T>(
    BuildContext context,
    Widget page,
  ) async {
    if (!context.mounted) return null;

    return Navigator.of(context).pushAndRemoveUntil<T>(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  /// Context-safe pop
    /// [context] - BuildContext
  /// [result] - Geri dönüş değeri (opsiyonel)
  static void pop<T>(BuildContext context, [T? result]) {
    if (!context.mounted) return;
    Navigator.of(context).pop(result);
  }

  /// Ekran genişliğini döndürür
    /// [context] - BuildContext
  /// Returns: Ekran genişliği
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Ekran yüksekliğini döndürür
    /// [context] - BuildContext
  /// Returns: Ekran yüksekliği
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Responsive genişlik hesaplar
    /// [context] - BuildContext
  /// [percentage] - Yüzde değeri (0.0 - 1.0)
  /// Returns: Hesaplanan genişlik
  static double getResponsiveWidth(BuildContext context, double percentage) {
    return getScreenWidth(context) * percentage;
  }

  /// Responsive yükseklik hesaplar
    /// [context] - BuildContext
  /// [percentage] - Yüzde değeri (0.0 - 1.0)
  /// Returns: Hesaplanan yükseklik
  static double getResponsiveHeight(BuildContext context, double percentage) {
    return getScreenHeight(context) * percentage;
  }

  /// Cihazın mobil olup olmadığını kontrol eder
    /// [context] - BuildContext
  /// Returns: true ise mobil, false ise tablet/desktop
  static bool isMobile(BuildContext context) {
    return getScreenWidth(context) < 600;
  }

  /// Cihazın tablet olup olmadığını kontrol eder
    /// [context] - BuildContext
  /// Returns: true ise tablet, false değilse
  static bool isTablet(BuildContext context) {
    final width = getScreenWidth(context);
    return width >= 600 && width < 1200;
  }

  /// Cihazın desktop olup olmadığını kontrol eder
    /// [context] - BuildContext
  /// Returns: true ise desktop, false değilse
  static bool isDesktop(BuildContext context) {
    return getScreenWidth(context) >= 1200;
  }
}
