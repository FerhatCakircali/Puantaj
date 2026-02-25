/// Türkçe alfabeye göre sıralama yardımcı fonksiyonları
class TurkishCollation {
  /// Türkçe alfabeye göre iki string'i karşılaştırır
  /// Türkçe karakterleri (ç, ğ, ı, ö, ş, ü) doğru sırayla işler
  static int compare(String a, String b) {
    const turkishAlphabet = [
      'a',
      'b',
      'c',
      'ç',
      'd',
      'e',
      'f',
      'g',
      'ğ',
      'h',
      'ı',
      'i',
      'j',
      'k',
      'l',
      'm',
      'n',
      'o',
      'ö',
      'p',
      'r',
      's',
      'ş',
      't',
      'u',
      'ü',
      'v',
      'y',
      'z',
    ];

    final Map<String, int> alphabetOrder = {
      for (var i = 0; i < turkishAlphabet.length; i++) turkishAlphabet[i]: i,
    };

    final na = _normalize(a);
    final nb = _normalize(b);

    final minLen = na.length < nb.length ? na.length : nb.length;
    for (var i = 0; i < minLen; i++) {
      final ca = na[i];
      final cb = nb[i];
      final ia = alphabetOrder[ca] ?? -1;
      final ib = alphabetOrder[cb] ?? -1;
      if (ia != ib) {
        return ia.compareTo(ib);
      }
    }
    return na.length.compareTo(nb.length);
  }

  /// String'i normalize eder (küçük harfe çevirir ve aksan işaretlerini kaldırır)
  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('û', 'u');
}
