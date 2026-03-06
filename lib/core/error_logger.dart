import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// ErrorLogger singleton sınıfı - Merkezi hata loglama sistemi.
///
/// Bu sınıf, uygulama genelinde tutarlı hata loglama sağlar ve
/// boş catch bloklarını ortadan kaldırır. Tüm hata, uyarı ve bilgi
/// mesajları bu sınıf üzerinden loglanır.
///
/// **Özellikler:**
/// - Singleton pattern (tek instance)
/// - Context bilgisi ile loglama
/// - Stack trace desteği
/// - Emoji indicator'lar (❌, ⚠️, ℹ️)
/// - Firebase Crashlytics entegrasyonu (production'da otomatik)
///
/// **Kullanım Örnekleri:**
/// ```dart
/// // Hata loglama
/// ErrorLogger.instance.logError(
///   'Ödeme eklenirken hata',
///   error: e,
///   stackTrace: stackTrace,
///   context: 'PaymentService.addPayment',
/// );
///
/// // Uyarı loglama
/// ErrorLogger.instance.logWarning(
///   'Kullanıcı oturumu bulunamadı',
///   context: 'WorkerService.getEmployees',
/// );
///
/// // Bilgi loglama
/// ErrorLogger.instance.logInfo(
///   'Ödeme başarıyla tamamlandı',
///   context: 'PaymentService.addPayment',
/// );
/// ```
///
/// Saat Dilimi: Europe/Istanbul (UTC+3)
class ErrorLogger {
  ErrorLogger._();

  /// Singleton instance
  static final ErrorLogger instance = ErrorLogger._();

  /// Factory constructor - singleton pattern
  factory ErrorLogger() => instance;

  /// Hata loglar (❌ emoji ile).
  ///
  /// Bu metod, kritik hataları loglar ve production'da Firebase Crashlytics'e
  /// otomatik olarak gönderir.
  ///
  /// Parametreler:
  /// - [message]: Hata mesajı (zorunlu)
  /// - [error]: Hata objesi (opsiyonel)
  /// - [stackTrace]: Stack trace (opsiyonel)
  /// - [context]: Hatanın oluştuğu yer (örn: 'PaymentService.addPayment')
  ///
  /// Örnek:
  /// ```dart
  /// try {
  ///   // Riskli işlem
  /// } catch (e, stackTrace) {
  ///   ErrorLogger.instance.logError(
  ///     'Ödeme eklenirken hata',
  ///     error: e,
  ///     stackTrace: stackTrace,
  ///     context: 'PaymentService.addPayment',
  ///   );
  /// }
  /// ```
  void logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
  }) {
    final contextPrefix = context != null ? '[$context] ' : '';
    final errorSuffix = error != null ? ': $error' : '';

    debugPrint('❌ $contextPrefix$message$errorSuffix');

    if (stackTrace != null) {
      debugPrint('❌ Stack trace: $stackTrace');
    }

    // 🔥 Firebase Crashlytics'e gönder (production'da)
    if (kReleaseMode && error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: '$contextPrefix$message',
        fatal: false,
      );
    }
  }

  /// Uyarı loglar (⚠️ emoji ile).
  ///
  /// Bu metod, kritik olmayan ama dikkat edilmesi gereken durumları loglar.
  /// Örneğin: null değer, boş liste, eksik veri gibi.
  ///
  /// Parametreler:
  /// - [message]: Uyarı mesajı (zorunlu)
  /// - [context]: Uyarının oluştuğu yer (opsiyonel)
  /// - [data]: Ek veri (opsiyonel, debug için)
  ///
  /// Örnek:
  /// ```dart
  /// if (userId == null) {
  ///   ErrorLogger.instance.logWarning(
  ///     'Kullanıcı oturumu bulunamadı',
  ///     context: 'WorkerService.getEmployees',
  ///   );
  ///   return [];
  /// }
  /// ```
  void logWarning(String message, {String? context, Object? data}) {
    final contextPrefix = context != null ? '[$context] ' : '';
    final dataSuffix = data != null ? ' - Data: $data' : '';

    debugPrint('⚠️ $contextPrefix$message$dataSuffix');
  }

  /// Bilgi loglar (ℹ️ emoji ile).
  ///
  /// Bu metod, normal akış bilgilerini loglar. Örneğin: başarılı işlemler,
  /// durum güncellemeleri, debug bilgileri.
  ///
  /// Parametreler:
  /// - [message]: Bilgi mesajı (zorunlu)
  /// - [context]: Bilginin oluştuğu yer (opsiyonel)
  /// - [data]: Ek veri (opsiyonel, debug için)
  ///
  /// Örnek:
  /// ```dart
  /// ErrorLogger.instance.logInfo(
  ///   'Ödeme başarıyla tamamlandı',
  ///   context: 'PaymentService.addPayment',
  ///   data: {'paymentId': paymentId, 'amount': amount},
  /// );
  /// ```
  void logInfo(String message, {String? context, Object? data}) {
    final contextPrefix = context != null ? '[$context] ' : '';
    final dataSuffix = data != null ? ' - Data: $data' : '';

    debugPrint('ℹ️ $contextPrefix$message$dataSuffix');
  }

  /// Başarı loglar (✅ emoji ile).
  ///
  /// Bu metod, başarılı işlemleri loglar. Özellikle kritik işlemlerin
  /// başarıyla tamamlandığını belirtmek için kullanılır.
  ///
  /// Parametreler:
  /// - [message]: Başarı mesajı (zorunlu)
  /// - [context]: İşlemin gerçekleştiği yer (opsiyonel)
  /// - [data]: Ek veri (opsiyonel, debug için)
  ///
  /// Örnek:
  /// ```dart
  /// ErrorLogger.instance.logSuccess(
  ///   'Worker başarıyla güncellendi',
  ///   context: 'WorkerService.updateWorker',
  ///   data: {'workerId': worker.id, 'name': worker.fullName},
  /// );
  /// ```
  void logSuccess(String message, {String? context, Object? data}) {
    final contextPrefix = context != null ? '[$context] ' : '';
    final dataSuffix = data != null ? ' - Data: $data' : '';

    debugPrint('✅ $contextPrefix$message$dataSuffix');
  }

  /// Debug loglar (🔍 emoji ile).
  ///
  /// Bu metod, geliştirme sırasında debug bilgilerini loglar.
  /// Production'da bu loglar gösterilmez.
  ///
  /// Parametreler:
  /// - [message]: Debug mesajı (zorunlu)
  /// - [context]: Debug bilgisinin oluştuğu yer (opsiyonel)
  /// - [data]: Ek veri (opsiyonel)
  ///
  /// Örnek:
  /// ```dart
  /// ErrorLogger.instance.logDebug(
  ///   'Worker ID ile sorgu yapılıyor',
  ///   context: 'WorkerService.getWorkerById',
  ///   data: {'workerId': workerId},
  /// );
  /// ```
  void logDebug(String message, {String? context, Object? data}) {
    if (kDebugMode) {
      final contextPrefix = context != null ? '[$context] ' : '';
      final dataSuffix = data != null ? ' - Data: $data' : '';

      debugPrint('🔍 $contextPrefix$message$dataSuffix');
    }
  }

  /// Bildirim loglar (📢 emoji ile).
  ///
  /// Bu metod, kullanıcıya gönderilen bildirimleri loglar.
  ///
  /// Parametreler:
  /// - [message]: Bildirim mesajı (zorunlu)
  /// - [context]: Bildirimin gönderildiği yer (opsiyonel)
  /// - [data]: Ek veri (opsiyonel)
  ///
  /// Örnek:
  /// ```dart
  /// ErrorLogger.instance.logNotification(
  ///   'Ödeme bildirimi gönderildi',
  ///   context: 'PaymentService.sendPaymentNotification',
  ///   data: {'workerId': workerId, 'amount': amount},
  /// );
  /// ```
  void logNotification(String message, {String? context, Object? data}) {
    final contextPrefix = context != null ? '[$context] ' : '';
    final dataSuffix = data != null ? ' - Data: $data' : '';

    debugPrint('📢 $contextPrefix$message$dataSuffix');
  }

  /// Para işlemi loglar (💰 emoji ile).
  ///
  /// Bu metod, ödeme, avans, masraf gibi para işlemlerini loglar.
  ///
  /// Parametreler:
  /// - [message]: İşlem mesajı (zorunlu)
  /// - [context]: İşlemin gerçekleştiği yer (opsiyonel)
  /// - [data]: Ek veri (opsiyonel, tutar bilgisi gibi)
  ///
  /// Örnek:
  /// ```dart
  /// ErrorLogger.instance.logPayment(
  ///   'Yeni ödeme ekleniyor',
  ///   context: 'PaymentService.addPayment',
  ///   data: {'amount': payment.amount, 'workerId': payment.workerId},
  /// );
  /// ```
  void logPayment(String message, {String? context, Object? data}) {
    final contextPrefix = context != null ? '[$context] ' : '';
    final dataSuffix = data != null ? ' - Data: $data' : '';

    debugPrint('💰 $contextPrefix$message$dataSuffix');
  }
}
