/// Ödeme zamanı hesaplama yardımcı sınıfı
class PaymentTimeHelper {
  /// Ödeme kaydının gösterim zamanını hesaplar
  ///
  /// Öncelik sırası: updated_at > created_at > payment_date
  static DateTime getDisplayTime(Map<String, dynamic> payment) {
    if (payment['updated_at'] != null) {
      return DateTime.parse(payment['updated_at'] as String).toLocal();
    } else if (payment['created_at'] != null) {
      return DateTime.parse(payment['created_at'] as String).toLocal();
    } else {
      return DateTime.parse(payment['payment_date'] as String);
    }
  }
}
