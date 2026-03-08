import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../../../../../models/attendance.dart';
import '../../pdf_report_utils.dart';
import '../../helpers/pdf_styles.dart';
import '../../helpers/pdf_svg_icons.dart';
import '../constants/employee_report_constants.dart';

/// Dönem bazlı devam kayıtları özeti oluşturucu
///
/// Çalışan raporları için dönem filtrelemeli devam kayıtları özet kartını oluşturur.
class PeriodAttendanceSummaryBuilder {
  PeriodAttendanceSummaryBuilder._();

  /// Devam kayıtları özeti kartı oluştur
  static pw.Widget build(
    List<Attendance> allDays,
    DateTime periodStart,
    DateTime periodEnd,
    PdfStyles styles,
  ) {
    final dateFormat = PdfReportUtils.dateFormat;
    final fullDayCount = allDays
        .where((a) => a.status == AttendanceStatus.fullDay)
        .length;
    final halfDayCount = allDays
        .where((a) => a.status == AttendanceStatus.halfDay)
        .length;
    final totalDays = fullDayCount + (halfDayCount * 0.5);
    final absentCount = allDays
        .where((a) => a.status == AttendanceStatus.absent)
        .length;

    return pw.Container(
      padding: styles.cardPadding,
      decoration: styles.premiumCard(PdfStyles.successColor),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            EmployeeReportConstants.attendanceSummaryTitle,
            style: styles.sectionHeaderStyle,
          ),
          pw.SizedBox(height: EmployeeReportConstants.sectionSpacing),
          pw.Row(
            children: [
              PdfSvgIcons.buildIcon(
                PdfSvgIcons.calendar,
                size: styles.iconSize,
              ),
              pw.SizedBox(width: styles.iconSpacing),
              pw.Text(
                '${EmployeeReportConstants.evaluationPrefix}'
                '${dateFormat.format(periodStart)} - ${dateFormat.format(periodEnd)}',
                style: styles.labelStyle,
              ),
            ],
          ),
          pw.SizedBox(height: EmployeeReportConstants.sectionSpacing),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.checkCircle,
                  EmployeeReportConstants.fullDayLabel,
                  '$fullDayCount',
                  PdfStyles.successColor,
                  styles,
                ),
              ),
              pw.SizedBox(width: EmployeeReportConstants.cardSpacing),
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.halfCircle,
                  EmployeeReportConstants.halfDayLabel,
                  '$halfDayCount',
                  PdfStyles.warningColor,
                  styles,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: EmployeeReportConstants.cardSpacing),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.sum,
                  EmployeeReportConstants.totalLabel,
                  totalDays.toStringAsFixed(1),
                  PdfStyles.primaryColor,
                  styles,
                ),
              ),
              pw.SizedBox(width: EmployeeReportConstants.cardSpacing),
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.xCircle,
                  EmployeeReportConstants.absentLabel,
                  '$absentCount',
                  PdfStyles.dangerColor,
                  styles,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// İstatistik kutusu oluştur
  static pw.Widget _buildStatBox(
    String svgIcon,
    String label,
    String value,
    PdfColor color,
    PdfStyles styles,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(EmployeeReportConstants.statBoxPadding),
      decoration: styles.statBox(color),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          PdfSvgIcons.buildIcon(svgIcon, size: styles.iconSize),
          pw.SizedBox(height: EmployeeReportConstants.iconSpacing),
          pw.Text(label, style: styles.labelStyle),
          pw.SizedBox(height: EmployeeReportConstants.smallSpacing),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: EmployeeReportConstants.statValueFontSize,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
