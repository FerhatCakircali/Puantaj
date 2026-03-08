/// Türkçe ay isimleri sabitleri
class TurkishMonths {
  static const List<String> names = [
    '',
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  /// Ay numarasından ay ismini döndürür
  static String getName(int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError('Ay numarası 1-12 arasında olmalıdır');
    }
    return names[month];
  }
}
