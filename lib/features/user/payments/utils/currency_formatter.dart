/// Para birimi formatlama yardımcı sınıfı
class CurrencyFormatter {
  /// Tutarı Türk Lirası formatında gösterir
  /// Örnek: 1000000 -> "1.000.000"
  static String format(double amount) {
    final intAmount = amount.toInt();
    final str = intAmount.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }

    return buffer.toString();
  }
}
