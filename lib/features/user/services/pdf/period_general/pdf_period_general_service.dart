import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';

import '../pdf_base_service.dart';
import '../../../../../models/employee.dart';
import '../../../../../models/attendance.dart';
import '../../../../../models/payment.dart';
import '../../../../../models/expense.dart';
import '../../../../../models/advance.dart';
import '../helpers/pdf_styles.dart';
import '../helpers/pdf_general_summary_helper.dart';
import '../helpers/pdf_general_table_helper.dart';
import '../helpers/pdf_expense_helper.dart';
import '../pdf_report_utils.dart';

import 'builders/financial_summary_builder.dart';
import 'calculators/period_financial_calculator.dart';
import 'constants/period_report_constants.dart';

/// Genel dönem raporu PDF oluşturma servisi
///
/// Orchestrator pattern kullanarak helper ve builder sınıflarını koordine eder
class PdfPeriodGeneralService {
  final PdfBaseService _base = PdfBaseService();

  Future<File> generate({
    required String periodTitle,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Employee> employees,
    required List<List<Attendance>> allAttendances,
    required List<List<Payment>> allPayments,
    required List<List<Advance>> allAdvances,
    required List<Expense> expenses,
    String? outputDirectory,
    Uint8List? robotoFontBytes,
    Uint8List? robotoBoldFontBytes,
  }) async {
    if (robotoFontBytes != null && robotoBoldFontBytes != null) {
      return _generateWithCustomFonts(
        periodTitle: periodTitle,
        periodStart: periodStart,
        periodEnd: periodEnd,
        employees: employees,
        allAttendances: allAttendances,
        allPayments: allPayments,
        allAdvances: allAdvances,
        expenses: expenses,
        outputDirectory: outputDirectory,
        robotoFontBytes: robotoFontBytes,
        robotoBoldFontBytes: robotoBoldFontBytes,
      );
    } else {
      await _base.loadFonts();
      return _generateWithDefaultFonts(
        periodTitle: periodTitle,
        periodStart: periodStart,
        periodEnd: periodEnd,
        employees: employees,
        allAttendances: allAttendances,
        allPayments: allPayments,
        allAdvances: allAdvances,
        expenses: expenses,
        outputDirectory: outputDirectory,
      );
    }
  }

  /// Custom fontlarla PDF oluşturur
  Future<File> _generateWithCustomFonts({
    required String periodTitle,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Employee> employees,
    required List<List<Attendance>> allAttendances,
    required List<List<Payment>> allPayments,
    required List<List<Advance>> allAdvances,
    required List<Expense> expenses,
    String? outputDirectory,
    required Uint8List robotoFontBytes,
    required Uint8List robotoBoldFontBytes,
  }) async {
    final baseFont = pw.Font.ttf(robotoFontBytes.buffer.asByteData());
    final boldFont = pw.Font.ttf(robotoBoldFontBytes.buffer.asByteData());
    final pdfTheme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);
    final pdf = pw.Document(theme: pdfTheme);

    final tempBase = PdfBaseService();
    tempBase.baseFont = baseFont;
    tempBase.boldFont = boldFont;

    final pages = _buildReportPages(
      base: tempBase,
      periodTitle: periodTitle,
      periodStart: periodStart,
      periodEnd: periodEnd,
      employees: employees,
      allAttendances: allAttendances,
      allPayments: allPayments,
      allAdvances: allAdvances,
      expenses: expenses,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(PeriodReportConstants.pageMargin),
        build: (pw.Context context) => pages,
      ),
    );

    return _savePdf(pdf, periodTitle, outputDirectory);
  }

  /// Default fontlarla PDF oluşturur
  Future<File> _generateWithDefaultFonts({
    required String periodTitle,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Employee> employees,
    required List<List<Attendance>> allAttendances,
    required List<List<Payment>> allPayments,
    required List<List<Advance>> allAdvances,
    required List<Expense> expenses,
    String? outputDirectory,
  }) async {
    final pdf = pw.Document(theme: _base.fontsLoaded ? _base.pdfTheme : null);

    final pages = _buildReportPages(
      base: _base,
      periodTitle: periodTitle,
      periodStart: periodStart,
      periodEnd: periodEnd,
      employees: employees,
      allAttendances: allAttendances,
      allPayments: allPayments,
      allAdvances: allAdvances,
      expenses: expenses,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(PeriodReportConstants.pageMargin),
        build: (pw.Context context) => pages,
      ),
    );

    return _savePdf(pdf, periodTitle, outputDirectory);
  }

  /// Rapor sayfalarını oluşturur (orchestrator)
  List<pw.Widget> _buildReportPages({
    required PdfBaseService base,
    required String periodTitle,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Employee> employees,
    required List<List<Attendance>> allAttendances,
    required List<List<Payment>> allPayments,
    required List<List<Advance>> allAdvances,
    required List<Expense> expenses,
  }) {
    final styles = PdfStyles(base);
    final summaryHelper = PdfGeneralSummaryHelper(styles);
    final tableHelper = PdfGeneralTableHelper(summaryHelper, base.boldFont);
    final financialBuilder = FinancialSummaryBuilder(
      styles: styles,
      base: base,
    );

    final calculator = PeriodFinancialCalculator.calculate(
      allPayments: allPayments,
      allAdvances: allAdvances,
      expenses: expenses,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );

    final pages = <pw.Widget>[];

    pages.add(_buildHeader(base, styles, periodTitle, periodStart, periodEnd));
    pages.add(pw.SizedBox(height: PeriodReportConstants.standardSpacing));

    pages.add(
      tableHelper.buildSummaryTable(
        employees: employees,
        allAttendances: allAttendances,
        allPayments: allPayments,
        allAdvances: allAdvances,
        periodStart: periodStart,
        periodEnd: periodEnd,
      ),
    );
    pages.add(pw.SizedBox(height: PeriodReportConstants.standardSpacing));

    if (expenses.isNotEmpty) {
      pages.add(
        PdfExpenseHelper.buildExpenseInfo(
          expenses,
          periodStart,
          periodEnd,
          styles,
        ),
      );
      pages.add(pw.SizedBox(height: PeriodReportConstants.standardSpacing));
    }

    pages.add(
      financialBuilder.build(
        employeeCount: employees.length,
        calculator: calculator,
      ),
    );

    pages.add(pw.SizedBox(height: PeriodReportConstants.standardSpacing));
    pages.add(_buildFooter());

    return pages;
  }

  /// Header oluşturur
  pw.Widget _buildHeader(
    PdfBaseService base,
    PdfStyles styles,
    String periodTitle,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    return pw.Container(
      padding: styles.largePadding,
      decoration: styles.premiumHeaderDecoration,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                PeriodReportConstants.reportTitle,
                style: styles.mainTitleStyle,
              ),
              pw.SizedBox(height: PeriodReportConstants.tinySpacing + 2),
              pw.Text(
                periodTitle,
                style: pw.TextStyle(
                  fontSize: PeriodReportConstants.mainTitleFontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  font: base.boldFont,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: PeriodReportConstants.headerPaddingHorizontal,
              vertical: PeriodReportConstants.headerPaddingVertical,
            ),
            decoration: pw.BoxDecoration(color: PdfColors.white),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  PeriodReportConstants.periodLabel,
                  style: pw.TextStyle(
                    fontSize: PeriodReportConstants.periodLabelFontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfStyles.neutralColor,
                    font: base.boldFont,
                    letterSpacing: PeriodReportConstants.letterSpacing,
                  ),
                ),
                pw.SizedBox(height: PeriodReportConstants.tinySpacing),
                pw.Text(
                  '${PdfReportUtils.dateFormat.format(periodStart)} - ${PdfReportUtils.dateFormat.format(periodEnd)}',
                  style: pw.TextStyle(
                    fontSize: PeriodReportConstants.periodValueFontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfStyles.darkColor,
                    font: base.boldFont,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Footer oluşturur
  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(
        top: PeriodReportConstants.standardSpacing,
      ),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfStyles.borderColor,
            width: PeriodReportConstants.borderWidth,
          ),
        ),
      ),
      child: pw.Center(
        child: pw.Column(
          children: [
            pw.Text(
              '${PeriodReportConstants.reportDateLabel}: ${PdfReportUtils.dateFormat.format(DateTime.now())}',
              style: pw.TextStyle(
                fontSize: PeriodReportConstants.footerFontSize,
                color: PdfStyles.neutralColor,
              ),
            ),
            pw.SizedBox(height: PeriodReportConstants.tinySpacing),
            pw.Text(
              '${PeriodReportConstants.pageLabel} 1',
              style: pw.TextStyle(
                fontSize: PeriodReportConstants.footerFontSize,
                color: PdfStyles.neutralColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// PDF'i kaydeder
  Future<File> _savePdf(
    pw.Document pdf,
    String periodTitle,
    String? outputDirectory,
  ) async {
    final outputPath = outputDirectory ?? (await getTemporaryDirectory()).path;
    final file = File(
      '$outputPath/${periodTitle.replaceAll(' ', '_')}_genel_rapor.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
