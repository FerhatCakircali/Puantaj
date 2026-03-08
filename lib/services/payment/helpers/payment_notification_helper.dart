import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/payment.dart';
import '../../../core/error_logger.dart';
import '../../../utils/currency_formatter.dart';
import '../constants/payment_constants.dart';

/// Ödeme bildirimlerini yöneten helper sınıfı
class PaymentNotificationHelper {
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Çalışana ödeme bildirimi gönderir
  ///
  /// [payment] Ödeme bilgisi
  /// [userId] Kullanıcı ID'si
  Future<void> sendPaymentNotification(Payment payment, int userId) async {
    try {
      final message =
          '${payment.fullDays} Tam Gün, ${payment.halfDays} Yarım Gün - Toplam ${CurrencyFormatter.formatWithSymbol(payment.amount)} ödendi';

      debugPrint('Ödeme bildirimi gönderiliyor: $message');

      await _supabase.from(PaymentConstants.notificationsTable).insert({
        'sender_id': userId,
        'sender_type': PaymentConstants.senderTypeUser,
        'recipient_id': payment.workerId,
        'recipient_type': PaymentConstants.recipientTypeWorker,
        'notification_type': PaymentConstants.notificationTypePaymentReceived,
        'title': PaymentConstants.notificationTitlePaymentMade,
        'message': message,
        'related_id': payment.workerId,
        'scheduled_time': null,
      });

      debugPrint('Ödeme bildirimi gönderildi');
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'PaymentNotificationHelper.sendPaymentNotification hatası',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
