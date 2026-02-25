import 'package:pdf/widgets.dart' as pw;
import '../pdf_report_utils.dart';
import '../../../../../../models/employee.dart';
import 'pdf_styles.dart';

/// Çalışan raporu için header bileşenleri
class PdfEmployeeReportHeader {
  /// Rapor başlığı oluştur
  static pw.Widget buildTitle(String periodTitle, PdfStyles styles) {
    return pw.Header(
      level: 0,
      child: pw.Text(periodTitle, style: styles.titleStyle),
    );
  }

  /// Çalışan bilgileri kartı oluştur
  static pw.Widget buildEmployeeInfo(Employee employee, PdfStyles styles) {
    final dateFormat = PdfReportUtils.dateFormat;

    return pw.Container(
      padding: styles.standardPadding,
      decoration: styles.cardDecoration,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ÇALIŞAN BİLGİLERİ', style: styles.headerStyle),
          pw.Divider(),
          _buildInfoRow('Ad Soyad:', employee.name, styles),
          pw.SizedBox(height: 5),
          _buildInfoRow('Unvan:', employee.title, styles),
          pw.SizedBox(height: 5),
          _buildInfoRow('Telefon:', employee.phone, styles),
          pw.SizedBox(height: 5),
          _buildInfoRow(
            'İşe Başlama Tarihi:',
            dateFormat.format(employee.startDate),
            styles,
          ),
        ],
      ),
    );
  }

  /// Bilgi satırı oluştur
  static pw.Widget _buildInfoRow(String label, String value, PdfStyles styles) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: styles.headerStyle),
        pw.Text(value),
      ],
    );
  }
}
