import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../pdf_base_service.dart';
import '../../helpers/pdf_styles.dart';
import '../../pdf_report_utils.dart';

/// Finansal özet grafik ve ilerleme çubuklarını oluşturur
class SummaryChartBuilder {
  final PdfBaseService base;
  final PdfStyles styles;

  SummaryChartBuilder(this.base) : styles = PdfStyles(base);

  /// Gider dağılımı kartını oluşturur
  pw.Widget buildExpenseDistributionCard({
    required double totalPayments,
    required double totalAdvances,
    required double totalExpenses,
    required double totalSpending,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: styles.cardDecoration,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'GİDER DAĞILIMI',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfStyles.darkColor,
              font: base.boldFont,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 20),
          buildProgressRow(
            'Çalışan Ödemeleri',
            totalPayments,
            totalSpending,
            PdfStyles.successColor,
          ),
          pw.SizedBox(height: 16),
          buildProgressRow(
            'Verilen Avanslar',
            totalAdvances,
            totalSpending,
            PdfStyles.warningColor,
          ),
          pw.SizedBox(height: 16),
          buildProgressRow(
            'Masraflar',
            totalExpenses,
            totalSpending,
            PdfStyles.primaryColor,
          ),
          pw.SizedBox(height: 20),
          _buildTotalSpendingBand(totalSpending),
        ],
      ),
    );
  }

  /// İlerleme çubuğu satırı oluşturur
  pw.Widget buildProgressRow(
    String label,
    double amount,
    double total,
    PdfColor color,
  ) {
    final percentage = total > 0 ? (amount / total) * 100 : 0.0;
    final progressWidth = percentage / 100;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, color: PdfStyles.darkColor),
            ),
            pw.Text(
              PdfReportUtils.formatCurrency(amount),
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfStyles.darkColor,
                font: base.boldFont,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(
              child: pw.Container(
                height: 4,
                child: pw.Stack(
                  children: [
                    pw.Container(
                      height: 4,
                      decoration: pw.BoxDecoration(color: PdfStyles.lightBg),
                    ),
                    pw.Container(
                      height: 4,
                      width: double.infinity,
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: (progressWidth * 100).toInt(),
                            child: pw.Container(
                              decoration: pw.BoxDecoration(color: color),
                            ),
                          ),
                          if (progressWidth < 1.0)
                            pw.Expanded(
                              flex: ((1 - progressWidth) * 100).toInt(),
                              child: pw.Container(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              '${percentage.toStringAsFixed(1)}%',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: color,
                font: base.boldFont,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTotalSpendingBand(double totalSpending) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: pw.BoxDecoration(
        color: PdfStyles.darkColor,
        boxShadow: [
          pw.BoxShadow(
            color: PdfColor.fromInt(0x33000000),
            offset: const PdfPoint(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'TOPLAM GİDER',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              font: base.boldFont,
              letterSpacing: 1.2,
            ),
          ),
          pw.Text(
            PdfReportUtils.formatCurrency(totalSpending),
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              font: base.boldFont,
            ),
          ),
        ],
      ),
    );
  }
}
