import 'package:pdf/widgets.dart' as pw;
import '../pdf_report_utils.dart';
import '../../../../../../models/employee.dart';
import 'pdf_styles.dart';

/// Çalışan raporu için footer bileşenleri
class PdfEmployeeReportFooter {
  /// Modern rapor footer'ı oluştur (minimal ve şık)
  static pw.Widget buildFooter(Employee employee) {
    final dateFormat = PdfReportUtils.dateFormat;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfStyles.borderColor, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Rapor Oluşturma Tarihi: ${dateFormat.format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 9, color: PdfStyles.neutralColor),
          ),
          pw.Text(
            'Çalışan: ${employee.name}',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfStyles.darkColor,
            ),
          ),
        ],
      ),
    );
  }
}
