import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../pdf_base_service.dart';
import '../../helpers/pdf_styles.dart';
import '../../pdf_report_utils.dart';

/// Finansal özet raporu başlık bileşenlerini oluşturur
class SummaryHeaderBuilder {
  final PdfBaseService base;
  final PdfStyles styles;

  SummaryHeaderBuilder(this.base) : styles = PdfStyles(base);

  /// Premium gradient başlık oluşturur
  pw.Widget buildHeader({
    required String periodTitle,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final dateFormat = PdfReportUtils.dateFormat;

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [
            PdfColor.fromInt(0xFF4F46E5),
            PdfColor.fromInt(0xFF6366F1),
            PdfColor.fromInt(0xFF818CF8),
          ],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColor.fromInt(0x334F46E5),
            offset: const PdfPoint(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          _buildTitleSection(periodTitle),
          _buildPeriodSection(periodStart, periodEnd, dateFormat),
        ],
      ),
    );
  }

  pw.Widget _buildTitleSection(String periodTitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('FİNANSAL ÖZET', style: styles.mainTitleStyle),
        pw.SizedBox(height: 6),
        pw.Text(
          periodTitle,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            font: base.boldFont,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPeriodSection(
    DateTime periodStart,
    DateTime periodEnd,
    dynamic dateFormat,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: pw.BoxDecoration(color: PdfColors.white),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'RAPOR DÖNEMİ',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfStyles.neutralColor,
              font: base.boldFont,
              letterSpacing: 1.0,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${dateFormat.format(periodStart)} - ${dateFormat.format(periodEnd)}',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfStyles.darkColor,
              font: base.boldFont,
            ),
          ),
        ],
      ),
    );
  }

  /// Footer oluşturur
  pw.Widget buildFooter() {
    final dateFormat = PdfReportUtils.dateFormat;

    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.5),
        ),
      ),
      child: pw.Center(
        child: pw.Column(
          children: [
            pw.Text(
              'Rapor Tarihi: ${dateFormat.format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 9, color: PdfStyles.neutralColor),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Sayfa 1',
              style: pw.TextStyle(fontSize: 9, color: PdfStyles.neutralColor),
            ),
          ],
        ),
      ),
    );
  }
}
