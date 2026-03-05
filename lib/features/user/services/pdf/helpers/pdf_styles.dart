import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../pdf_base_service.dart';

/// PDF stil tanımlamaları - Premium Kurumsal Tasarım Sistemi
/// Bento Box Style ile modern, şık ve profesyonel tasarım
class PdfStyles {
  final PdfBaseService _base;

  PdfStyles(this._base);

  // Base service getter (font erişimi için)
  PdfBaseService get base => _base;

  // ============================================
  // RENK PALETİ - Premium Kurumsal Renkler
  // ============================================
  static const primaryColor = PdfColor.fromInt(0xFF3730A3); // Deep Slate Blue
  static const primaryLight = PdfColor.fromInt(0xFF6366F1); // Refined Indigo
  static const primaryDark = PdfColor.fromInt(0xFF2D2580); // Darker Blue
  static const successColor = PdfColor.fromInt(0xFF10B981); // Yeşil
  static const warningColor = PdfColor.fromInt(0xFFF59E0B); // Turuncu
  static const dangerColor = PdfColor.fromInt(0xFFE11D48); // Rose
  static const darkColor = PdfColor.fromInt(0xFF0F172A); // Koyu
  static const neutralColor = PdfColor.fromInt(0xFF64748B); // Slate
  static const lightBg = PdfColor.fromInt(0xFFF8FAFC); // Açık arka plan (Zebra)
  static const borderColor = PdfColor.fromInt(0xFFE2E8F0); // Border

  // ============================================
  // TİPOGRAFİ - Premium ve Okunabilir
  // ============================================

  /// Ana başlık stili (26pt, bold, beyaz, letter-spacing: 0.8)
  pw.TextStyle get mainTitleStyle => pw.TextStyle(
    fontSize: 26,
    fontWeight: pw.FontWeight.bold,
    font: _base.boldFont,
    color: PdfColors.white,
    letterSpacing: 0.8,
  );

  /// Section başlık stili (14pt, bold, primary, letter-spacing: 1.5, UPPERCASE)
  pw.TextStyle get sectionHeaderStyle => pw.TextStyle(
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
    font: _base.boldFont,
    color: primaryColor,
    letterSpacing: 1.5,
  );

  /// Kart başlık stili (12pt, bold, dark)
  pw.TextStyle get cardHeaderStyle => pw.TextStyle(
    fontWeight: pw.FontWeight.bold,
    fontSize: 12,
    font: _base.boldFont,
    color: darkColor,
    letterSpacing: 0.5,
  );

  /// Büyük sayı stili (24pt, bold, primary)
  pw.TextStyle get bigNumberStyle => pw.TextStyle(
    fontSize: 24,
    fontWeight: pw.FontWeight.bold,
    font: _base.boldFont,
    color: primaryColor,
  );

  /// Label stili (10pt, neutral)
  pw.TextStyle get labelStyle =>
      pw.TextStyle(fontSize: 10, font: _base.baseFont, color: neutralColor);

  /// Normal veri stili (10pt, dark)
  pw.TextStyle get dataStyle =>
      pw.TextStyle(fontSize: 10, font: _base.baseFont, color: darkColor);

  /// Beyaz header stili (tablolar için, 11pt, bold, ortala)
  pw.TextStyle get tableHeaderStyle => pw.TextStyle(
    fontWeight: pw.FontWeight.bold,
    fontSize: 11,
    font: _base.boldFont,
    color: PdfColors.white,
    letterSpacing: 0.5,
  );

  /// Footer stili (10pt, neutral)
  pw.TextStyle get footerStyle =>
      pw.TextStyle(fontSize: 10, font: _base.baseFont, color: neutralColor);

  /// Success stili (10pt, bold, success color)
  pw.TextStyle get successStyle => pw.TextStyle(
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
    font: _base.boldFont,
    color: successColor,
  );

  /// Warning stili (10pt, bold, warning color)
  pw.TextStyle get warningStyle => pw.TextStyle(
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
    font: _base.boldFont,
    color: warningColor,
  );

  /// Header stili (12pt, bold, primary, uppercase)
  pw.TextStyle get headerStyle => pw.TextStyle(
    fontSize: 12,
    fontWeight: pw.FontWeight.bold,
    font: _base.boldFont,
    color: primaryColor,
    letterSpacing: 1.2,
  );

  /// Beyaz header stili (tablolar için, 11pt, bold, beyaz)
  pw.TextStyle get whiteHeaderStyle => pw.TextStyle(
    fontWeight: pw.FontWeight.bold,
    fontSize: 11,
    font: _base.boldFont,
    color: PdfColors.white,
    letterSpacing: 0.5,
  );

  // ============================================
  // DEKORASYONLAR - Bento Box Style (KESKİN KÖŞELER)
  // ============================================

  /// Premium gradient header (3 renkli, sol üst -> sağ alt)
  pw.BoxDecoration get premiumHeaderDecoration => pw.BoxDecoration(
    gradient: pw.LinearGradient(
      colors: [primaryDark, primaryColor, primaryLight],
      begin: pw.Alignment.topLeft,
      end: pw.Alignment.bottomRight,
      stops: [0.0, 0.5, 1.0],
    ),
    boxShadow: [
      pw.BoxShadow(
        color: PdfColor.fromInt(0x333730A3),
        offset: const PdfPoint(0, 6),
        blurRadius: 16,
      ),
    ],
  );

  /// Premium Card (sol border 4px, beyaz arka plan, 20px padding)
  pw.BoxDecoration premiumCard(PdfColor borderColor) => pw.BoxDecoration(
    color: PdfColors.white,
    border: pw.Border(
      left: pw.BorderSide(color: borderColor, width: 4),
      top: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
      right: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
      bottom: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
    ),
  );

  /// Stat Box (üst border 3px, beyaz arka plan)
  pw.BoxDecoration statBox(PdfColor accentColor) => pw.BoxDecoration(
    color: PdfColors.white,
    border: pw.Border(
      top: pw.BorderSide(color: accentColor, width: 3),
      left: pw.BorderSide(color: borderColor, width: 0.5),
      right: pw.BorderSide(color: borderColor, width: 0.5),
      bottom: pw.BorderSide(color: borderColor, width: 0.5),
    ),
  );

  /// Tablo header dekorasyonu (yatay gradient, Primary -> PrimaryLight)
  pw.BoxDecoration get tableHeaderDecoration => pw.BoxDecoration(
    gradient: pw.LinearGradient(
      colors: [primaryColor, primaryLight],
      begin: pw.Alignment.centerLeft,
      end: pw.Alignment.centerRight,
    ),
  );

  /// Zebra striping (çift satırlar için açık gri arka plan)
  pw.BoxDecoration get zebraStriping => pw.BoxDecoration(color: lightBg);

  /// Alternate row decoration (zebra striping için)
  pw.BoxDecoration get alternateRowDecoration =>
      pw.BoxDecoration(color: lightBg);

  /// Genel kart dekorasyonu (beyaz arka plan, border)
  pw.BoxDecoration get cardDecoration => pw.BoxDecoration(
    color: PdfColors.white,
    border: pw.Border.all(color: borderColor, width: 0.5),
  );

  /// Warning card dekorasyonu (sol border turuncu)
  pw.BoxDecoration get warningCardDecoration => premiumCard(warningColor);

  /// Primary card dekorasyonu (sol border primary)
  pw.BoxDecoration get primaryCardDecoration => premiumCard(primaryColor);

  // ============================================
  // BOŞLUKLAR (HASSAS ÖLÇÜLER)
  // ============================================

  /// Premium header padding (24px)
  pw.EdgeInsets get headerPadding => const pw.EdgeInsets.all(24);

  /// Large padding (24px - Premium header için)
  pw.EdgeInsets get largePadding => const pw.EdgeInsets.all(24);

  /// Standard padding (20px - Kartlar için)
  pw.EdgeInsets get standardPadding => const pw.EdgeInsets.all(20);

  /// Kart padding (20px - Bento style)
  pw.EdgeInsets get cardPadding => const pw.EdgeInsets.all(20);

  /// Tablo cell padding (10px)
  pw.EdgeInsets get cellPadding => const pw.EdgeInsets.all(10);

  /// İkon ile metin arası boşluk (10px)
  double get iconSpacing => 10;

  /// İkon boyutu (14px)
  double get iconSize => 14;
}
