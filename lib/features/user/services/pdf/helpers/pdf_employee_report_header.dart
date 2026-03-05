import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../pdf_report_utils.dart';
import '../../../../../../models/employee.dart';
import 'pdf_styles.dart';
import 'pdf_svg_icons.dart';

/// Çalışan raporu için header bileşenleri - Premium Bento Style
class PdfEmployeeReportHeader {
  /// Premium rapor başlığı oluştur
  static pw.Widget buildTitle(String periodTitle, PdfStyles styles) {
    return pw.Container(
      padding: styles.headerPadding,
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfStyles.primaryColor, PdfStyles.primaryLight],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(periodTitle, style: styles.mainTitleStyle),
              pw.SizedBox(height: 6),
              pw.Text(
                'Dönemsel Performans Raporu',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromInt(0xFFD1D5DB),
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: pw.BoxDecoration(color: PdfColors.white),
            child: pw.Text(
              DateFormat('dd.MM.yyyy').format(DateTime.now()),
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfStyles.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Premium çalışan bilgileri kartı oluştur
  static pw.Widget buildEmployeeInfo(Employee employee, PdfStyles styles) {
    final dateFormat = PdfReportUtils.dateFormat;

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
            'İşe Başlama',
            dateFormat.format(employee.startDate),
            styles,
          ),
        ],
      ),
    );
  }

  /// Premium bilgi satırı oluştur
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
