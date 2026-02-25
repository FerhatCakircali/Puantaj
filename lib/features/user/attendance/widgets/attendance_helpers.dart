/// Yevmiye ekranı için yardımcı fonksiyonlar
class AttendanceHelpers {
  /// Türkçe alfabeye göre string karşılaştırma
  static int collateTurkish(String a, String b) {
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

    String normalize(String s) => s
        .toLowerCase()
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u');

    final na = normalize(a);
    final nb = normalize(b);

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
}
