/// Para formatını Türk formatına çevir (örn: 123456.50 -> 123.456,50)
class CurrencyFormatter {
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
}
