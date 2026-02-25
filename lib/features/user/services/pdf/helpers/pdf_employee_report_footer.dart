import 'package:pdf/widgets.dart' as pw;
import '../pdf_report_utils.dart';
import '../../../../../../models/employee.dart';

/// Çalışan raporu için footer bileşenleri
class PdfEmployeeReportFooter {
  /// Rapor footer'ı oluştur
  static pw.Widget buildFooter(Employee employee) {
    final dateFormat = PdfReportUtils.dateFormat;

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Bu rapor ${employee.name} için oluşturulmuştur.'),
              pw.Text('Oluşturma Tarihi: ${dateFormat.format(DateTime.now())}'),
            ],
          ),
        ],
      ),
    );
  }
}
