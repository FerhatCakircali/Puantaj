/// Sayı formatlama yardımcı fonksiyonları

/// Double değeri binlik ayırıcı ile formatlar
/// Örnek: 600234.0 → "600.234"
String formatAmount(double amount) {
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

/// Double extension ile kullanım kolaylığı
extension DoubleFormatter on double {
  /// Binlik ayırıcı ile formatla
  String toFormattedString() => formatAmount(this);
}
