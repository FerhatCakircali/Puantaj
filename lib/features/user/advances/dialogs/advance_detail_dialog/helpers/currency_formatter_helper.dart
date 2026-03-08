/// Para birimi formatlama yardımcı sınıfı
class CurrencyFormatterHelper {
  /// Tutarı Türk Lirası formatında döndürür
  ///
  /// Örnek: 1000.0 → ₺1.000
  static String formatAmount(double amount) {
    final intAmount = amount.toInt();
    final formatted = intAmount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '₺$formatted';
  }
}
