import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../../../../../models/advance.dart';
import '../../pdf_report_utils.dart';
import '../../helpers/pdf_styles.dart';
import '../../helpers/pdf_svg_icons.dart';
import '../constants/employee_report_constants.dart';
import '../filters/period_filter.dart';

/// Dönem bazlı avans bilgileri oluşturucu
///
/// Çalışan raporları için dönem filtrelemeli avans bilgileri kartını oluşturur.
class PeriodAdvanceInfoBuilder {
  PeriodAdvanceInfoBuilder._();

  /// Avans bilgileri kartı oluştur
  static pw.Widget build(
    List<Advance> advances,
    DateTime periodStart,
    DateTime periodEnd,
    PdfStyles styles,
  ) {
    final periodAdvances = PeriodFilter.filterAdvances(
      advances,
      periodStart,
      periodEnd,
    );

    final totalAdvances = advances.fold<double>(
      0,
      (sum, advance) => sum + advance.amount,
    );

    final deductedAdvances = advances
        .where((a) => a.isDeducted)
        .fold<double>(0, (sum, advance) => sum + advance.amount);

    final pendingAdvances = advances
        .where((a) => !a.isDeducted)
        .fold<double>(0, (sum, advance) => sum + advance.amount);

    if (advances.isEmpty) {
      return pw.Container(
        padding: styles.cardPadding,
        decoration: styles.premiumCard(PdfStyles.successColor),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              EmployeeReportConstants.advanceInfoTitle,
              style: styles.sectionHeaderStyle,
            ),
            pw.SizedBox(height: EmployeeReportConstants.sectionSpacing),
            pw.Container(
              padding: const pw.EdgeInsets.all(
                EmployeeReportConstants.statBoxPadding,
              ),
              decoration: pw.BoxDecoration(color: PdfStyles.lightBg),
              child: pw.Text(
                EmployeeReportConstants.noAdvanceMessage,
                style: styles.dataStyle,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      padding: styles.cardPadding,
      decoration: styles.premiumCard(PdfStyles.warningColor),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            EmployeeReportConstants.advanceInfoTitle,
            style: styles.sectionHeaderStyle,
          ),
          pw.SizedBox(height: EmployeeReportConstants.sectionSpacing),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.handMoney,
                  EmployeeReportConstants.totalAdvanceLabel,
                  PdfReportUtils.formatCurrency(totalAdvances),
                  PdfStyles.warningColor,
                  styles,
                ),
              ),
              pw.SizedBox(width: EmployeeReportConstants.cardSpacing),
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.checkCircle,
                  EmployeeReportConstants.deductedLabel,
                  PdfReportUtils.formatCurrency(deductedAdvances),
                  PdfStyles.successColor,
                  styles,
                ),
              ),
              pw.SizedBox(width: EmployeeReportConstants.cardSpacing),
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.xCircle,
                  EmployeeReportConstants.pendingLabel,
                  PdfReportUtils.formatCurrency(pendingAdvances),
                  PdfStyles.dangerColor,
                  styles,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: EmployeeReportConstants.sectionSpacing),
          periodAdvances.isEmpty
              ? pw.Container(
                  padding: const pw.EdgeInsets.all(
                    EmployeeReportConstants.statBoxPadding,
                  ),
                  decoration: pw.BoxDecoration(color: PdfStyles.lightBg),
                  child: pw.Text(
                    EmployeeReportConstants.noPeriodAdvanceMessage,
                    style: styles.dataStyle,
                  ),
                )
              : _buildAdvanceTable(periodAdvances, styles),
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

  /// Avans tablosu oluştur
  static pw.Widget _buildAdvanceTable(
    List<Advance> advances,
    PdfStyles styles,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: [
        EmployeeReportConstants.dateHeader,
        EmployeeReportConstants.amountHeader,
        EmployeeReportConstants.statusHeader,
        EmployeeReportConstants.descriptionHeader,
      ],
      data: advances.map((advance) {
        final dateFormat = PdfReportUtils.dateFormat;
        return [
          dateFormat.format(advance.advanceDate),
          PdfReportUtils.formatCurrency(advance.amount),
          advance.isDeducted
              ? EmployeeReportConstants.deductedStatus
              : EmployeeReportConstants.pendingStatus,
          advance.description ?? EmployeeReportConstants.noDescription,
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
