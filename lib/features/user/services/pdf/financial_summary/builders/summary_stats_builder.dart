import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../pdf_base_service.dart';
import '../../helpers/pdf_styles.dart';
import '../../pdf_report_utils.dart';

/// Finansal özet istatistik kartlarını oluşturur
class SummaryStatsBuilder {
  final PdfBaseService base;
  final PdfStyles styles;

  SummaryStatsBuilder(this.base) : styles = PdfStyles(base);

  /// Executive dashboard kartlarını oluşturur
  pw.Widget buildExecutiveDashboard({
    required double totalPayments,
    required double totalAdvances,
    required double totalExpenses,
  }) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _buildExecutiveCard(
            'Çalışan Ödemeleri',
            PdfReportUtils.formatCurrency(totalPayments),
            PdfStyles.successColor,
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: _buildExecutiveCard(
            'Verilen Avanslar',
            PdfReportUtils.formatCurrency(totalAdvances),
            PdfStyles.warningColor,
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: _buildExecutiveCard(
            'Masraflar',
            PdfReportUtils.formatCurrency(totalExpenses),
            PdfStyles.primaryColor,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildExecutiveCard(
    String label,
    String value,
    PdfColor accentColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border(
          top: pw.BorderSide(color: accentColor, width: 3),
          left: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
          right: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
          bottom: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
        ),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColor.fromInt(0x0A000000),
            offset: const PdfPoint(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfStyles.neutralColor,
              letterSpacing: 1.0,
              fontWeight: pw.FontWeight.bold,
              font: base.boldFont,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
              font: base.boldFont,
            ),
          ),
        ],
      ),
    );
  }

  /// Avans durumu kartını oluşturur
  pw.Widget buildAdvanceStatusCard({
    required double totalAdvances,
    required double deductedAdvances,
    required double pendingAdvances,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border(
          top: pw.BorderSide(color: PdfStyles.primaryColor, width: 3),
          left: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
          right: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
          bottom: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
        ),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColor.fromInt(0x0A000000),
            offset: const PdfPoint(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'AVANS DURUMU',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfStyles.darkColor,
              font: base.boldFont,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 20),
          _buildInfoRowWithDot(
            'Toplam Verilen',
            PdfReportUtils.formatCurrency(totalAdvances),
            PdfStyles.primaryColor,
          ),
          pw.SizedBox(height: 16),
          _buildInfoRowWithDot(
            'Düşülmüş',
            PdfReportUtils.formatCurrency(deductedAdvances),
            PdfStyles.successColor,
          ),
          pw.SizedBox(height: 16),
          _buildInfoRowWithDot(
            'Bekleyen',
            PdfReportUtils.formatCurrency(pendingAdvances),
            PdfStyles.warningColor,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRowWithDot(
    String label,
    String value,
    PdfColor dotColor,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 6,
              height: 6,
              decoration: pw.BoxDecoration(
                color: dotColor,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 11, color: PdfStyles.darkColor),
            ),
          ],
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: dotColor,
            font: base.boldFont,
          ),
        ),
      ],
    );
  }
}
