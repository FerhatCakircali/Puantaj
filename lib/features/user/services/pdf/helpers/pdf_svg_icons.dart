import 'package:pdf/widgets.dart' as pw;

/// Minimalist SVG ikonlar - Premium kurumsal tasarım için
/// İkon boyutu: 14x14px
class PdfSvgIcons {
  /// Kullanıcı ikonu (Ad/İsim için)
  static String get user => '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="7" cy="4" r="2.5" stroke="#64748B" stroke-width="1.2" fill="none"/>
  <path d="M2 12C2 9.5 4 8 7 8C10 8 12 9.5 12 12" stroke="#64748B" stroke-width="1.2" stroke-linecap="round" fill="none"/>
</svg>
''';

  /// Telefon ikonu
  static String get phone => '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="4" y="2" width="6" height="10" rx="1" stroke="#64748B" stroke-width="1.2" fill="none"/>
  <line x1="6" y1="10" x2="8" y2="10" stroke="#64748B" stroke-width="1.2" stroke-linecap="round"/>
</svg>
''';

  /// Takvim ikonu (Tarih için)
  static String get calendar => '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="2" y="3" width="10" height="9" rx="1" stroke="#64748B" stroke-width="1.2" fill="none"/>
  <line x1="2" y1="6" x2="12" y2="6" stroke="#64748B" stroke-width="1.2"/>
  <line x1="5" y1="2" x2="5" y2="4" stroke="#64748B" stroke-width="1.2" stroke-linecap="round"/>
  <line x1="9" y1="2" x2="9" y2="4" stroke="#64748B" stroke-width="1.2" stroke-linecap="round"/>
</svg>
''';

  /// Rozet ikonu (Unvan için)
  static String get badge => '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="7" cy="6" r="3.5" stroke="#64748B" stroke-width="1.2" fill="none"/>
  <path d="M5 10L4 13L7 11.5L10 13L9 10" stroke="#64748B" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>
''';

  /// Onay ikonu (Tam Gün için)
  static String get checkCircle => '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="7" cy="7" r="5" stroke="#10B981" stroke-width="1.2" fill="none"/>
  <path d="M5 7L6.5 8.5L9 6" stroke="#10B981" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>
''';

  /// Yarım daire ikonu (Yarım Gün için)
  static String get halfCircle => '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M7 2C4.24 2 2 4.24 2 7C2 9.76 4.24 12 7 12" stroke="#F59E0B" stroke-width="1.2" stroke-linecap="round" fill="none"/>
  <line x1="7" y1="2" x2="7" y2="12" stroke="#F59E0B" stroke-width="1.2"/>
</svg>
''';

  /// X ikonu (Devamsızlık için)
  static String get xCircle => '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="7" cy="7" r="5" stroke="#E11D48" stroke-width="1.2" fill="none"/>
  <line x1="5" y1="5" x2="9" y2="9" stroke="#E11D48" stroke-width="1.2" stroke-linecap="round"/>
  <line x1="9" y1="5" x2="5" y2="9" stroke="#E11D48" stroke-width="1.2" stroke-linecap="round"/>
</svg>
''';

  /// Para ikonu (Ödeme için)
  static String get money => '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="2" y="4" width="10" height="6" rx="1" stroke="#64748B" stroke-width="1.2" fill="none"/>
  <circle cx="7" cy="7" r="1.5" stroke="#64748B" stroke-width="1.2" fill="none"/>
  <line x1="3" y1="7" x2="4" y2="7" stroke="#64748B" stroke-width="1.2"/>
  <line x1="10" y1="7" x2="11" y2="7" stroke="#64748B" stroke-width="1.2"/>
</svg>
''';

  /// Avans ikonu (El ile para)
  static String get handMoney => '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M3 8L3 11C3 11.5 3.5 12 4 12L10 12C10.5 12 11 11.5 11 11L11 6" stroke="#64748B" stroke-width="1.2" stroke-linecap="round" fill="none"/>
  <path d="M11 6L11 4C11 3.5 10.5 3 10 3L9 3" stroke="#64748B" stroke-width="1.2" stroke-linecap="round" fill="none"/>
  <line x1="6" y1="3" x2="6" y2="8" stroke="#64748B" stroke-width="1.2" stroke-linecap="round"/>
  <circle cx="7" cy="5" r="1.5" stroke="#64748B" stroke-width="1" fill="none"/>
</svg>
''';

  /// Toplam ikonu (Sigma)
  static String get sum => '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M4 3H10L7 7L10 11H4" stroke="#64748B" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>
''';

  /// Masraf ikonu (Alışveriş çantası)
  static String get shopping => '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M3 5L2.5 11.5C2.5 11.8 2.7 12 3 12H11C11.3 12 11.5 11.8 11.5 11.5L11 5" stroke="#64748B" stroke-width="1.2" stroke-linecap="round" fill="none"/>
  <path d="M5 5V4C5 2.9 5.9 2 7 2C8.1 2 9 2.9 9 4V5" stroke="#64748B" stroke-width="1.2" stroke-linecap="round" fill="none"/>
  <line x1="3" y1="5" x2="11" y2="5" stroke="#64748B" stroke-width="1.2"/>
</svg>
''';

  /// Çalışan ikonu (Grup)
  static String get users => '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="5" cy="4" r="1.5" stroke="#64748B" stroke-width="1.2" fill="none"/>
  <circle cx="9" cy="4" r="1.5" stroke="#64748B" stroke-width="1.2" fill="none"/>
  <path d="M2 11C2 9.5 3.5 8.5 5 8.5C6.5 8.5 8 9.5 8 11" stroke="#64748B" stroke-width="1.2" stroke-linecap="round" fill="none"/>
  <path d="M6 11C6 9.5 7.5 8.5 9 8.5C10.5 8.5 12 9.5 12 11" stroke="#64748B" stroke-width="1.2" stroke-linecap="round" fill="none"/>
</svg>
''';

  /// Düşülmüş ikonu (Onay işareti)
  static String get deducted => '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M3 7L6 10L11 4" stroke="#10B981" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>
''';

  /// Bekleyen ikonu (Saat)
  static String get pending => '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="7" cy="7" r="5" stroke="#F59E0B" stroke-width="1.2" fill="none"/>
  <path d="M7 4V7L9 9" stroke="#F59E0B" stroke-width="1.2" stroke-linecap="round" fill="none"/>
</svg>
''';

  /// SVG ikonunu pw.Widget olarak döndür
  static pw.Widget buildIcon(String svgString, {double? size}) {
    return pw.SvgImage(svg: svgString, width: size ?? 14, height: size ?? 14);
  }
}
