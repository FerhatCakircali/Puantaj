/// CurrencyFormatter utility sınıfı - Uygulama genelinde tutarlı para birimi formatlama.
///
/// Bu utility, servis ve UI dosyalarındaki kod tekrarını ortadan kaldırmak için
/// standartlaştırılmış para birimi formatlama metodları sağlar.
///
/// **Türk Lirası Formatı:**
/// - Binlik ayırıcı: Nokta (.)
/// - Ondalık ayırıcı: Virgül (,)
/// - Para birimi sembolü: ₺
///
/// **Örnekler:**
/// - 1000 → "1.000"
/// - 1000000 → "1.000.000"
/// - 1234.56 → "1.234,56"
/// - 1000 → "₺1.000" (sembol ile)
///
/// Saat Dilimi: Europe/Istanbul (UTC+3)
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Türk Lirası sembolü
  static const String currencySymbol = '₺';

  /// Tutarı Türk Lirası formatında gösterir (binlik ayırıcı nokta).
  ///
  /// Bu metod, tam sayı ve ondalıklı sayıları Türk formatında formatlar:
  /// - Binlik ayırıcı olarak nokta (.) kullanır
  /// - Ondalık kısım varsa virgül (,) ile ayırır
  /// - Ondalık kısım 00 ise göstermez
  ///
  /// Örnek:
  /// ```dart
  /// final formatted1 = CurrencyFormatter.format(1000);
  /// print(formatted1); // "1.000"
  ///
  /// final formatted2 = CurrencyFormatter.format(1234.56);
  /// print(formatted2); // "1.234,56"
  ///
  /// final formatted3 = CurrencyFormatter.format(1000000);
  /// print(formatted3); // "1.000.000"
  /// ```
  static String format(double amount) {
    // Tam sayı mı kontrol et
    final isWholeNumber = amount == amount.truncateToDouble();

    // Eğer tam sayıysa ondalık kısmı gösterme
    final formattedAmount = isWholeNumber
        ? amount.truncate().toString()
        : amount.toStringAsFixed(2);

    // Sayıyı parçalara ayır (tam kısım ve ondalık kısım)
    final parts = formattedAmount.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : null;

    // Tam kısmı 3'er basamakta nokta ile ayır
    final buffer = StringBuffer();
    var count = 0;

    for (var i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(integerPart[i]);
      count++;
    }

    // Ters çevir
    final formattedInteger = buffer.toString().split('').reversed.join('');

    // Ondalık kısım varsa virgül ile ekle
    if (decimalPart != null && decimalPart != '00') {
      return '$formattedInteger,$decimalPart';
    }

    return formattedInteger;
  }

  /// Tutarı sembol olmadan formatlar (sadece sayı).
  ///
  /// Bu metod, para birimi sembolü olmadan sadece formatlanmış sayıyı döndürür.
  /// Binlik ayırıcı olarak nokta (.) kullanır.
  ///
  /// Örnek:
  /// ```dart
  /// final formatted = CurrencyFormatter.formatWithoutSymbol(1000);
  /// print(formatted); // "1.000"
  /// ```
  ///
  /// Not: Bu metod [format] metodunun alias'ıdır.
  static String formatWithoutSymbol(double amount) {
    return format(amount);
  }

  /// Tutarı Türk Lirası sembolü (₺) ile birlikte formatlar.
  ///
  /// Bu metod, formatlanmış tutarın başına ₺ sembolü ekler.
  ///
  /// Örnek:
  /// ```dart
  /// final formatted = CurrencyFormatter.formatWithSymbol(1000);
  /// print(formatted); // "₺1.000"
  ///
  /// final formatted2 = CurrencyFormatter.formatWithSymbol(1234.56);
  /// print(formatted2); // "₺1.234,56"
  /// ```
  static String formatWithSymbol(double amount) {
    return '$currencySymbol${format(amount)}';
  }

  /// Formatlanmış string'i double'a parse eder.
  ///
  /// Türk formatındaki para birimi string'ini (nokta ve virgül içeren)
  /// double değere dönüştürür. Sembol varsa temizler.
  ///
  /// Örnek:
  /// ```dart
  /// final amount1 = CurrencyFormatter.parse("1.000");
  /// print(amount1); // 1000.0
  ///
  /// final amount2 = CurrencyFormatter.parse("1.234,56");
  /// print(amount2); // 1234.56
  ///
  /// final amount3 = CurrencyFormatter.parse("₺1.000");
  /// print(amount3); // 1000.0
  /// ```
  ///
  /// Geçersiz format durumunda 0.0 döndürür.
  static double parse(String formattedAmount) {
    try {
      // Sembolü temizle
      var cleaned = formattedAmount.replaceAll(currencySymbol, '').trim();

      // Binlik ayırıcı noktaları temizle
      cleaned = cleaned.replaceAll('.', '');

      // Ondalık virgülü noktaya çevir
      cleaned = cleaned.replaceAll(',', '.');

      return double.parse(cleaned);
    } catch (e) {
      return 0.0;
    }
  }

  /// Tutarı basit formatta gösterir (sadece tam kısım, binlik ayırıcı ile).
  ///
  /// Bu metod, ondalık kısmı göstermeden sadece tam sayı kısmını formatlar.
  /// Özellikle UI'da yer tasarrufu için kullanışlıdır.
  ///
  /// Örnek:
  /// ```dart
  /// final formatted = CurrencyFormatter.formatSimple(1234.56);
  /// print(formatted); // "1.234"
  /// ```
  static String formatSimple(double amount) {
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
