import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../../../../../../../models/employee.dart';
import '../../../../../../../models/attendance.dart';
import '../../helpers/pdf_styles.dart';
import '../../helpers/pdf_svg_icons.dart';

/// Devam kayıtları özeti PDF widget'ı oluşturucu - Premium Bento Style
class AttendanceSummaryBuilder {
  static pw.Widget build(
    Employee employee,
    List<Attendance> allDays,
    PdfStyles styles,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final fullDaysCount = allDays
        .where((a) => a.status == AttendanceStatus.fullDay)
        .length;
    final halfDaysCount = allDays
        .where((a) => a.status == AttendanceStatus.halfDay)
        .length;
    final absentDaysCount = allDays
        .where((a) => a.status == AttendanceStatus.absent)
        .length;
    final totalWorkedDays = fullDaysCount + (halfDaysCount * 0.5);

    return pw.Container(
      padding: styles.cardPadding,
      decoration: styles.premiumCard(PdfStyles.successColor),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('DEVAM KAYITLARI ÖZETİ', style: styles.sectionHeaderStyle),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              PdfSvgIcons.buildIcon(
                PdfSvgIcons.calendar,
                size: styles.iconSize,
              ),
              pw.SizedBox(width: styles.iconSpacing),
              pw.Text(
                'Değerlendirme: ${dateFormat.format(employee.startDate)} - ${dateFormat.format(DateTime.now())}',
                style: styles.labelStyle,
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBox(
                PdfSvgIcons.checkCircle,
                'Tam Gün',
                '$fullDaysCount',
                PdfStyles.successColor,
                styles,
              ),
              pw.SizedBox(width: 12),
              _buildStatBox(
                PdfSvgIcons.halfCircle,
                'Yarım Gün',
                '$halfDaysCount',
                PdfStyles.warningColor,
                styles,
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBox(
                PdfSvgIcons.sum,
                'Toplam Gün',
                totalWorkedDays.toStringAsFixed(1),
                PdfStyles.primaryColor,
                styles,
              ),
              pw.SizedBox(width: 12),
              _buildStatBox(
                PdfSvgIcons.xCircle,
                'Devamsızlık',
                '$absentDaysCount',
                PdfStyles.dangerColor,
                styles,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatBox(
    String svgIcon,
    String label,
    String value,
    PdfColor accentColor,
    PdfStyles styles,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: styles.statBox(accentColor),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PdfSvgIcons.buildIcon(svgIcon, size: styles.iconSize),
            pw.SizedBox(height: 8),
            pw.Text(label, style: styles.labelStyle),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
