import 'package:flutter/foundation.dart';

/// Merkezi hata yönetim sınıfı
///
/// Uygulama genelinde tutarlı hata yönetimi sağlar.
/// Single Responsibility prensibi gereği sadece hata yönetiminden sorumludur.
///
/// Kullanım:
/// ```dart
/// try {
///   // Riskli işlem
/// } catch (e, stack) {
///   ErrorHandler.logError('İşlem başarısız', e, stack);
/// }
/// ```
class ErrorHandler {
  /// Singleton instance
  static final ErrorHandler _instance = ErrorHandler._internal();

  /// Factory constructor - singleton pattern
  factory ErrorHandler() => _instance;

  ErrorHandler._internal();

  /// Hata loglama - production'da farklı davranabilir
  ///
  /// [context] - Hatanın oluştuğu bağlam (örn: 'NotificationService.init')
  /// [error] - Hata nesnesi
  /// [stackTrace] - Stack trace (opsiyonel)
  /// [additionalInfo] - Ek bilgi (opsiyonel)
  static void logError(
    String context,
    dynamic error, [
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalInfo,
  ]) {
    if (kDebugMode) {
      debugPrint(
        '╔═══════════════════════════════════════════════════════════',
      );
      debugPrint('║ ❌ HATA: $context');
      debugPrint(
        '╠═══════════════════════════════════════════════════════════',
      );
      debugPrint('║ Hata Detayı: $error');
      if (additionalInfo != null && additionalInfo.isNotEmpty) {
        debugPrint('║ Ek Bilgi:');
        additionalInfo.forEach((key, value) {
          debugPrint('║   • $key: $value');
        });
      }
      if (stackTrace != null) {
        debugPrint('║ Stack Trace:');
        final stackLines = stackTrace.toString().split('\n');
        for (var line in stackLines.take(5)) {
          // İlk 5 satır
          debugPrint('║   $line');
        }
      }
      debugPrint(
        '╚═══════════════════════════════════════════════════════════',
      );
    } else {
      // Production'da daha az detaylı log
      debugPrint('ERROR [$context]: $error');
    }

    // TODO: Production'da Sentry, Firebase Crashlytics vb. entegre edilebilir
    // _sendToErrorTracking(context, error, stackTrace, additionalInfo);
  }

  /// Bilgi loglama
  ///
  /// [context] - Bilginin oluştuğu bağlam
  /// [message] - Bilgi mesajı
  /// [data] - Ek veri (opsiyonel)
  static void logInfo(
    String context,
    String message, [
    Map<String, dynamic>? data,
  ]) {
    if (kDebugMode) {
      debugPrint('ℹ️ [$context] $message');
      if (data != null && data.isNotEmpty) {
        data.forEach((key, value) {
          debugPrint('  • $key: $value');
        });
      }
    }
  }

  /// Uyarı loglama
  ///
  /// [context] - Uyarının oluştuğu bağlam
  /// [message] - Uyarı mesajı
  /// [data] - Ek veri (opsiyonel)
  static void logWarning(
    String context,
    String message, [
    Map<String, dynamic>? data,
  ]) {
    if (kDebugMode) {
      debugPrint('⚠️ [$context] $message');
      if (data != null && data.isNotEmpty) {
        data.forEach((key, value) {
          debugPrint('  • $key: $value');
        });
      }
    }
  }

  /// Başarı loglama
  ///
  /// [context] - Başarının oluştuğu bağlam
  /// [message] - Başarı mesajı
  /// [data] - Ek veri (opsiyonel)
  static void logSuccess(
    String context,
    String message, [
    Map<String, dynamic>? data,
  ]) {
    if (kDebugMode) {
      debugPrint('✅ [$context] $message');
      if (data != null && data.isNotEmpty) {
        data.forEach((key, value) {
          debugPrint('  • $key: $value');
        });
      }
    }
  }

  /// Debug loglama (sadece debug modda)
  ///
  /// [context] - Debug bilgisinin oluştuğu bağlam
  /// [message] - Debug mesajı
  /// [data] - Ek veri (opsiyonel)
  static void logDebug(
    String context,
    String message, [
    Map<String, dynamic>? data,
  ]) {
    if (kDebugMode) {
      debugPrint('🔍 [$context] $message');
      if (data != null && data.isNotEmpty) {
        data.forEach((key, value) {
          debugPrint('  • $key: $value');
        });
      }
    }
  }

  /// Hata mesajını kullanıcı dostu formata çevirir
  ///
  /// [error] - Hata nesnesi
  /// Returns: Kullanıcı dostu hata mesajı
  static String getUserFriendlyMessage(dynamic error) {
    if (error == null) return 'Bilinmeyen bir hata oluştu';

    final errorString = error.toString().toLowerCase();

    // Yaygın hata türleri için özel mesajlar
    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection')) {
      return 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.';
    }

    if (errorString.contains('timeout')) {
      return 'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.';
    }

    if (errorString.contains('permission')) {
      return 'İzin hatası. Lütfen gerekli izinleri verin.';
    }

    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'İstenen kaynak bulunamadı.';
    }

    if (errorString.contains('unauthorized') ||
        errorString.contains('401') ||
        errorString.contains('403')) {
      return 'Yetkilendirme hatası. Lütfen tekrar giriş yapın.';
    }

    // Varsayılan mesaj
    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }

  /// Hata durumunda güvenli fallback değeri döndürür
  ///
  /// [operation] - Çalıştırılacak işlem
  /// [fallback] - Hata durumunda dönecek değer
  /// [context] - Hata bağlamı
  /// Returns: İşlem sonucu veya fallback değeri
  static T safeExecute<T>(T Function() operation, T fallback, String context) {
    try {
      return operation();
    } catch (e, stack) {
      logError(context, e, stack);
      return fallback;
    }
  }

  /// Async hata durumunda güvenli fallback değeri döndürür
  ///
  /// [operation] - Çalıştırılacak async işlem
  /// [fallback] - Hata durumunda dönecek değer
  /// [context] - Hata bağlamı
  /// Returns: İşlem sonucu veya fallback değeri
  static Future<T> safeExecuteAsync<T>(
    Future<T> Function() operation,
    T fallback,
    String context,
  ) async {
    try {
      return await operation();
    } catch (e, stack) {
      logError(context, e, stack);
      return fallback;
    }
  }
}
