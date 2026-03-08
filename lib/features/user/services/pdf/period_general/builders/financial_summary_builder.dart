import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../pdf_base_service.dart';
import '../../helpers/pdf_styles.dart';
import '../../pdf_report_utils.dart';
import '../calculators/period_financial_calculator.dart';
import '../constants/period_report_constants.dart';
import 'stat_card_builder.dart';

/// Finansal özet kartı builder'ı
///
/// Dönem finansal özet kartını oluşturur
class FinancialSummaryBuilder {
  final PdfStyles styles;
  final PdfBaseService base;
  final StatCardBuilder statCardBuilder;

  FinancialSummaryBuilder({required this.styles, required this.base})
    : statCardBuilder = StatCardBuilder(styles: styles, base: base);

  /// Finansal özet kartını oluşturur
  pw.Widget build({
    required int employeeCount,
    required PeriodFinancialCalculator calculator,
  }) {
    return pw.Container(
      padding: styles.standardPadding,
      decoration: styles.primaryCardDecoration,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          pw.SizedBox(height: PeriodReportConstants.largeSpacing),
          _buildStatCards(employeeCount, calculator),
          pw.SizedBox(height: PeriodReportConstants.largeSpacing),
          _buildAdvanceDetails(calculator),
          pw.SizedBox(height: PeriodReportConstants.largeSpacing),
          _buildTotalSpending(calculator.totalSpending),
        ],
      ),
    );
  }

  /// Başlık oluşturur
  pw.Widget _buildTitle() {
    return pw.Text(
      PeriodReportConstants.financialSummaryTitle,
      style: pw.TextStyle(
        font: base.boldFont,
        fontSize: PeriodReportConstants.sectionTitleFontSize,
        color: PdfStyles.primaryColor,
      ),
    );
  }

  /// İstatistik kartlarını oluşturur
  pw.Widget _buildStatCards(
    int employeeCount,
    PeriodFinancialCalculator calculator,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            statCardBuilder.build(
              label: PeriodReportConstants.employeeLabel,
              value: '$employeeCount',
              color: PdfStyles.primaryColor,
            ),
            pw.SizedBox(width: PeriodReportConstants.smallSpacing),
            statCardBuilder.build(
              label: PeriodReportConstants.paymentsLabel,
              value: PdfReportUtils.formatCurrency(calculator.totalPayments),
              color: PdfStyles.successColor,
            ),
          ],
        ),
        pw.SizedBox(height: PeriodReportConstants.smallSpacing),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            statCardBuilder.build(
              label: PeriodReportConstants.advancesLabel,
              value: PdfReportUtils.formatCurrency(calculator.totalAdvances),
              color: PdfStyles.warningColor,
            ),
            pw.SizedBox(width: PeriodReportConstants.smallSpacing),
            statCardBuilder.build(
              label: PeriodReportConstants.expensesLabel,
              value: PdfReportUtils.formatCurrency(calculator.totalExpenses),
              color: PdfStyles.dangerColor,
            ),
          ],
        ),
      ],
    );
  }

  /// Avans detaylarını oluşturur
  pw.Widget _buildAdvanceDetails(PeriodFinancialCalculator calculator) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(
        PeriodReportConstants.advanceCardPadding,
      ),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfStyles.warningColor,
            width: PeriodReportConstants.topBorderWidth,
          ),
          left: pw.BorderSide(
            color: PdfStyles.borderColor,
            width: PeriodReportConstants.borderWidth,
          ),
          right: pw.BorderSide(
            color: PdfStyles.borderColor,
            width: PeriodReportConstants.borderWidth,
          ),
          bottom: pw.BorderSide(
            color: PdfStyles.borderColor,
            width: PeriodReportConstants.borderWidth,
          ),
        ),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColor.fromInt(0x0A000000),
            offset: const PdfPoint(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: pw.Column(
        children: [
          _buildAdvanceRow(
            label: PeriodReportConstants.deductedAdvanceLabel,
            value: calculator.deductedAdvances,
            color: PdfStyles.successColor,
          ),
          pw.SizedBox(height: PeriodReportConstants.largeSpacing),
          _buildAdvanceRow(
            label: PeriodReportConstants.pendingAdvanceLabel,
            value: calculator.pendingAdvances,
            color: PdfStyles.warningColor,
          ),
        ],
      ),
    );
  }

  /// Avans satırı oluşturur
  pw.Widget _buildAdvanceRow({
    required String label,
    required double value,
    required PdfColor color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: PeriodReportConstants.dotSize,
              height: PeriodReportConstants.dotSize,
              decoration: pw.BoxDecoration(
                color: color,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.SizedBox(width: PeriodReportConstants.smallSpacing),
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: PeriodReportConstants.advanceDetailFontSize,
                color: PdfStyles.darkColor,
              ),
            ),
          ],
        ),
        pw.Text(
          PdfReportUtils.formatCurrency(value),
          style: pw.TextStyle(
            fontSize: PeriodReportConstants.advanceValueFontSize,
            fontWeight: pw.FontWeight.bold,
            color: color,
            font: base.boldFont,
          ),
        ),
      ],
    );
  }

  /// Toplam gider bandını oluşturur
  pw.Widget _buildTotalSpending(double totalSpending) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        vertical: PeriodReportConstants.totalSpendingPaddingVertical,
        horizontal: PeriodReportConstants.totalSpendingPaddingHorizontal,
      ),
      decoration: pw.BoxDecoration(
        color: PdfStyles.darkColor,
        boxShadow: [
          pw.BoxShadow(
            color: PdfColor.fromInt(0x33000000),
            offset: const PdfPoint(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            PeriodReportConstants.totalSpendingLabel,
            style: pw.TextStyle(
              font: base.boldFont,
              fontSize: PeriodReportConstants.totalSpendingLabelFontSize,
              color: PdfColors.white,
              letterSpacing: PeriodReportConstants.totalSpendingLetterSpacing,
            ),
          ),
          pw.Text(
            PdfReportUtils.formatCurrency(totalSpending),
            style: pw.TextStyle(
              font: base.boldFont,
              fontSize: PeriodReportConstants.totalSpendingValueFontSize,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
