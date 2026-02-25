import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../pdf_base_service.dart';

/// PDF stil tanımlamaları için merkezi helper sınıfı
class PdfStyles {
  final PdfBaseService _base;

  PdfStyles(this._base);

  /// Başlık stili (20pt, bold)
  pw.TextStyle get titleStyle => pw.TextStyle(
    fontSize: 20,
    fontWeight: pw.FontWeight.bold,
    font: _base.boldFont,
  );

  /// Header stili (12pt, bold)
  pw.TextStyle get headerStyle => pw.TextStyle(
    fontWeight: pw.FontWeight.bold,
    fontSize: 12,
    font: _base.boldFont,
  );

  /// Normal veri stili (10pt)
  pw.TextStyle get dataStyle =>
      pw.TextStyle(fontSize: 10, font: _base.baseFont);

  /// Tablo header dekorasyonu
  pw.BoxDecoration get tableHeaderDecoration =>
      pw.BoxDecoration(color: PdfColors.grey300);

  /// Kart container dekorasyonu
  pw.BoxDecoration get cardDecoration => pw.BoxDecoration(
    border: pw.Border.all(),
    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
  );

  /// Standart padding
  pw.EdgeInsets get standardPadding => const pw.EdgeInsets.all(10);

  /// Tablo cell padding
  pw.EdgeInsets get cellPadding => const pw.EdgeInsets.all(5);
}
