import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../../../../../models/attendance.dart';
import '../../../../../../models/payment.dart';
import '../../../../../../models/advance.dart';
import '../../pdf_report_utils.dart';
import '../../helpers/pdf_styles.dart';
import '../constants/employee_report_constants.dart';
import '../builders/period_attendance_summary_builder.dart';
import '../builders/period_payment_info_builder.dart';
import '../builders/period_advance_info_builder.dart';

/// Çalışan raporu tablo yardımcısı
///
/// Çalışan raporları için tablo bileşenlerini koordine eder.
class EmployeeReportTableHelper {
  EmployeeReportTableHelper._();

  /// Devam kayıtları özeti kartı oluştur
  static pw.Widget buildAttendanceSummary(
    List<Attendance> allDays,
    DateTime periodStart,
    DateTime periodEnd,
    PdfStyles styles,
  ) {
    return PeriodAttendanceSummaryBuilder.build(
      allDays,
      periodStart,
      periodEnd,
      styles,
    );
  }

  /// Ödeme bilgileri kartı oluştur
  static pw.Widget buildPaymentInfo(
    List<Payment> payments,
    List<Attendance> allDays,
    DateTime periodStart,
    DateTime periodEnd,
    PdfStyles styles,
  ) {
    return PeriodPaymentInfoBuilder.build(
      payments,
      allDays,
      periodStart,
      periodEnd,
      styles,
    );
  }

  /// Avans bilgileri kartı oluştur
  static pw.Widget buildAdvanceInfo(
    List<Advance> advances,
    DateTime periodStart,
    DateTime periodEnd,
    PdfStyles styles,
  ) {
    return PeriodAdvanceInfoBuilder.build(
      advances,
      periodStart,
      periodEnd,
      styles,
    );
  }

  /// Devam kayıtları tablosu oluştur
  static pw.Widget? buildAttendanceTable(
    List<Attendance> allDays,
    AttendanceStatus status,
    String title,
    PdfStyles styles,
  ) {
    final filteredDays = allDays.where((a) => a.status == status).toList();

    if (filteredDays.isEmpty) return null;

    final dateFormat = PdfReportUtils.dateFormat;

    PdfColor borderColor;
    if (status == AttendanceStatus.fullDay) {
      borderColor = PdfStyles.successColor;
    } else if (status == AttendanceStatus.halfDay) {
      borderColor = PdfStyles.warningColor;
    } else {
      borderColor = PdfStyles.dangerColor;
    }

    return pw.Container(
      padding: styles.cardPadding,
      decoration: styles.premiumCard(borderColor),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: styles.sectionHeaderStyle),
          pw.SizedBox(height: EmployeeReportConstants.sectionSpacing),
          pw.Table(
            border: pw.TableBorder.all(color: PdfStyles.borderColor),
            children: [
              pw.TableRow(
                decoration: styles.tableHeaderDecoration,
                children: [
                  _buildTableCell(
                    EmployeeReportConstants.dateHeader,
                    styles,
                    isHeader: true,
                  ),
                ],
              ),
              ...filteredDays.asMap().entries.map((entry) {
                final index = entry.key;
                final attendance = entry.value;
                return pw.TableRow(
                  decoration: index % 2 == 0 ? styles.zebraStriping : null,
                  children: [
                    _buildTableCell(dateFormat.format(attendance.date), styles),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  /// Tablo hücresi oluştur
  static pw.Widget _buildTableCell(
    String text,
    PdfStyles styles, {
    bool isHeader = false,
  }) {
    return pw.Padding(
      padding: styles.cellPadding,
      child: pw.Center(
        child: pw.Text(
          text,
          style: isHeader ? styles.tableHeaderStyle : styles.dataStyle,
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }
}
