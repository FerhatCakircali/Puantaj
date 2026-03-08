/// Türkçe karakter sıralama yardımcısı
///
/// Türkçe karakterleri doğru sırayla karşılaştırır.
class TurkishTextComparator {
  TurkishTextComparator._();

  static const Map<String, int> _turkishOrder = {
    'a': 1,
    'A': 1,
    'b': 2,
    'B': 2,
    'c': 3,
    'C': 3,
    'ç': 4,
    'Ç': 4,
    'd': 5,
    'D': 5,
    'e': 6,
    'E': 6,
    'f': 7,
    'F': 7,
    'g': 8,
    'G': 8,
    'ğ': 9,
    'Ğ': 9,
    'h': 10,
    'H': 10,
    'ı': 11,
    'I': 11,
    'i': 12,
    'İ': 12,
    'j': 13,
    'J': 13,
    'k': 14,
    'K': 14,
    'l': 15,
    'L': 15,
    'm': 16,
    'M': 16,
    'n': 17,
    'N': 17,
    'o': 18,
    'O': 18,
    'ö': 19,
    'Ö': 19,
    'p': 20,
    'P': 20,
    'r': 21,
    'R': 21,
    's': 22,
    'S': 22,
    'ş': 23,
    'Ş': 23,
    't': 24,
    'T': 24,
    'u': 25,
    'U': 25,
    'ü': 26,
    'Ü': 26,
    'v': 27,
    'V': 27,
    'y': 28,
    'Y': 28,
    'z': 29,
    'Z': 29,
  };

  /// İki metni Türkçe karakter sırasına göre karşılaştırır
  static int compare(String a, String b) {
    final aLower = a.toLowerCase();
    final bLower = b.toLowerCase();

    for (int i = 0; i < aLower.length && i < bLower.length; i++) {
      final aOrder = _turkishOrder[aLower[i]] ?? 999;
      final bOrder = _turkishOrder[bLower[i]] ?? 999;

      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }
    }

    return aLower.length.compareTo(bLower.length);
  }
}
