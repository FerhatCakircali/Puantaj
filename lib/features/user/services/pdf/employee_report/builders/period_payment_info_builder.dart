import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:math';
import '../../../../../../models/payment.dart';
import '../../../../../../models/attendance.dart';
import '../../pdf_report_utils.dart';
import '../../helpers/pdf_styles.dart';
import '../../helpers/pdf_svg_icons.dart';
import '../constants/employee_report_constants.dart';
import '../filters/period_filter.dart';

/// Dönem bazlı ödeme bilgileri oluşturucu
class PeriodPaymentInfoBuilder {
  PeriodPaymentInfoBuilder._();

  static pw.Widget build(
    List<Payment> payments,
    List<Attendance> allDays,
    DateTime periodStart,
    DateTime periodEnd,
    PdfStyles styles,
  ) {
    final periodPayments = PeriodFilter.filterPayments(
      payments,
      periodStart,
      periodEnd,
    );

    final totalPaid = periodPayments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );

    final totalWorkedDays =
        allDays.where((a) => a.status == AttendanceStatus.fullDay).length +
        (allDays.where((a) => a.status == AttendanceStatus.halfDay).length *
            0.5);

    final totalPaidDays = periodPayments.fold<double>(
      0,
      (sum, payment) => sum + payment.fullDays + (payment.halfDays * 0.5),
    );

    final unpaidDays = max(0.0, totalWorkedDays - totalPaidDays);

    return pw.Container(
      padding: styles.cardPadding,
      decoration: styles.premiumCard(PdfStyles.warningColor),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            EmployeeReportConstants.paymentInfoTitle,
            style: styles.sectionHeaderStyle,
          ),
          pw.SizedBox(height: EmployeeReportConstants.sectionSpacing),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.money,
                  EmployeeReportConstants.totalPaidLabel,
                  PdfReportUtils.formatCurrency(totalPaid),
                  PdfStyles.successColor,
                  styles,
                ),
              ),
              pw.SizedBox(width: EmployeeReportConstants.cardSpacing),
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.checkCircle,
                  EmployeeReportConstants.paidDaysLabel,
                  totalPaidDays.toStringAsFixed(1),
                  PdfStyles.primaryColor,
                  styles,
                ),
              ),
              pw.SizedBox(width: EmployeeReportConstants.cardSpacing),
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.xCircle,
                  EmployeeReportConstants.unpaidDaysLabel,
                  unpaidDays.toStringAsFixed(1),
                  PdfStyles.dangerColor,
                  styles,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: EmployeeReportConstants.sectionSpacing),
          periodPayments.isEmpty
              ? pw.Container(
                  padding: const pw.EdgeInsets.all(
                    EmployeeReportConstants.statBoxPadding,
                  ),
                  decoration: pw.BoxDecoration(color: PdfStyles.lightBg),
                  child: pw.Text(
                    EmployeeReportConstants.noPaymentMessage,
                    style: styles.dataStyle,
                  ),
                )
              : _buildPaymentTable(periodPayments, styles),
        ],
      ),
    );
  }

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

  static pw.Widget _buildPaymentTable(
    List<Payment> payments,
    PdfStyles styles,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: [
        EmployeeReportConstants.dateHeader,
        EmployeeReportConstants.fullDayHeader,
        EmployeeReportConstants.halfDayHeader,
        EmployeeReportConstants.paymentHeader,
      ],
      data: payments.map((payment) {
        final dateFormat = PdfReportUtils.dateFormat;
        return [
          dateFormat.format(payment.paymentDate),
          '${payment.fullDays}',
          '${payment.halfDays}',
          PdfReportUtils.formatCurrency(payment.amount),
        ];
      }).toList(),
      border: pw.TableBorder.all(color: PdfStyles.borderColor),
      headerStyle: pw.TextStyle(
        fontSize: EmployeeReportConstants.headerFontSize,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        font: styles.base.boldFont,
      ),
      headerDecoration: styles.tableHeaderDecoration,
      headerAlignment: pw.Alignment.center,
      headerPadding: styles.cellPadding,
      cellStyle: styles.dataStyle,
      cellAlignment: pw.Alignment.center,
      cellPadding: styles.cellPadding,
      oddRowDecoration: styles.zebraStriping,
      headerCount: 1,
    );
  }
}
