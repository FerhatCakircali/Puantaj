import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../../../../../models/employee.dart';
import '../../helpers/pdf_styles.dart';
import '../../helpers/pdf_svg_icons.dart';

/// Çalışan bilgileri PDF widget'ı oluşturucu - Premium Bento Style
class EmployeeInfoBuilder {
  static pw.Widget build(Employee employee, PdfStyles styles) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return pw.Container(
      padding: styles.cardPadding,
      decoration: styles.premiumCard(PdfStyles.primaryColor),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ÇALIŞAN BİLGİLERİ', style: styles.sectionHeaderStyle),
          pw.SizedBox(height: 16),
          _buildInfoRow(PdfSvgIcons.user, 'Ad Soyad', employee.name, styles),
          pw.SizedBox(height: 12),
          _buildInfoRow(PdfSvgIcons.badge, 'Unvan', employee.title, styles),
          pw.SizedBox(height: 12),
          _buildInfoRow(PdfSvgIcons.phone, 'Telefon', employee.phone, styles),
          pw.SizedBox(height: 12),
          _buildInfoRow(
            PdfSvgIcons.calendar,
            'İşe Başlama Tarihi',
            dateFormat.format(employee.startDate),
            styles,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(
    String svgIcon,
    String label,
    String value,
    PdfStyles styles,
  ) {
    return pw.Row(
      children: [
        PdfSvgIcons.buildIcon(svgIcon, size: styles.iconSize),
        pw.SizedBox(width: styles.iconSpacing),
        pw.Expanded(
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(label, style: styles.labelStyle),
              pw.Text(value, style: styles.dataStyle),
            ],
          ),
        ),
      ],
    );
  }
}
