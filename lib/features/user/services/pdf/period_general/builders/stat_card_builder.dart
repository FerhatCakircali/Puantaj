import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../pdf_base_service.dart';
import '../../helpers/pdf_styles.dart';
import '../constants/period_report_constants.dart';

/// İstatistik kartı builder'ı
///
/// Küçük istatistik kartları oluşturur
class StatCardBuilder {
  final PdfStyles styles;
  final PdfBaseService base;

  const StatCardBuilder({required this.styles, required this.base});

  /// İstatistik kartı oluşturur
  pw.Widget build({
    required String label,
    required String value,
    required PdfColor color,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(PeriodReportConstants.cardPadding),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(
            color: PdfStyles.borderColor,
            width: PeriodReportConstants.borderWidth,
          ),
          boxShadow: [
            pw.BoxShadow(
              color: PdfColor.fromInt(0x0A000000),
              offset: const PdfPoint(0, 1),
              blurRadius: 4,
            ),
          ],
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: PeriodReportConstants.statLabelFontSize,
                color: PdfStyles.neutralColor,
                fontWeight: pw.FontWeight.bold,
                font: base.boldFont,
              ),
            ),
            pw.SizedBox(height: PeriodReportConstants.smallSpacing),
            pw.Text(
              value,
              style: pw.TextStyle(
                font: base.boldFont,
                fontSize: PeriodReportConstants.statValueFontSize,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
