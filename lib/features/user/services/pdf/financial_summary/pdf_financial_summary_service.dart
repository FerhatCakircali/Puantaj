import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import '../pdf_base_service.dart';
import '../../../../../models/payment.dart';
import '../../../../../models/advance.dart';
import '../../../../../models/expense.dart';
import 'constants/financial_summary_constants.dart';
import 'calculators/financial_calculator.dart';
import 'filters/period_filter.dart';
import 'builders/summary_header_builder.dart';
import 'builders/summary_stats_builder.dart';
import 'builders/summary_chart_builder.dart';
import 'builders/summary_table_builder.dart';

/// Finansal özet raporu PDF oluşturma servisi
class PdfFinancialSummaryService {
  final PdfBaseService _base = PdfBaseService();

  Future<File> generate({
    required String periodTitle,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Payment> allPayments,
    required List<Advance> allAdvances,
    required List<Expense> allExpenses,
    String? outputDirectory,
    Uint8List? robotoFontBytes,
    Uint8List? robotoBoldFontBytes,
  }) async {
    if (robotoFontBytes != null && robotoBoldFontBytes != null) {
      return _generateWithCustomFonts(
        periodTitle: periodTitle,
        periodStart: periodStart,
        periodEnd: periodEnd,
        allPayments: allPayments,
        allAdvances: allAdvances,
        allExpenses: allExpenses,
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
        allPayments: allPayments,
        allAdvances: allAdvances,
        allExpenses: allExpenses,
        outputDirectory: outputDirectory,
      );
    }
  }

  Future<File> _generateWithCustomFonts({
    required String periodTitle,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Payment> allPayments,
    required List<Advance> allAdvances,
    required List<Expense> allExpenses,
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
      allPayments: allPayments,
      allAdvances: allAdvances,
      allExpenses: allExpenses,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: FinancialSummaryConstants.pageMargin,
        build: (pw.Context context) => pages,
      ),
    );

    return _savePdf(pdf, periodTitle, outputDirectory);
  }

  Future<File> _generateWithDefaultFonts({
    required String periodTitle,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Payment> allPayments,
    required List<Advance> allAdvances,
    required List<Expense> allExpenses,
    String? outputDirectory,
  }) async {
    final pdf = pw.Document(theme: _base.fontsLoaded ? _base.pdfTheme : null);

    final pages = _buildReportPages(
      base: _base,
      periodTitle: periodTitle,
      periodStart: periodStart,
      periodEnd: periodEnd,
      allPayments: allPayments,
      allAdvances: allAdvances,
      allExpenses: allExpenses,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: FinancialSummaryConstants.pageMargin,
        build: (pw.Context context) => pages,
      ),
    );

    return _savePdf(pdf, periodTitle, outputDirectory);
  }

  List<pw.Widget> _buildReportPages({
    required PdfBaseService base,
    required String periodTitle,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Payment> allPayments,
    required List<Advance> allAdvances,
    required List<Expense> allExpenses,
  }) {
    final pages = <pw.Widget>[];
    final filter = PeriodFilter();
    final calculator = FinancialCalculator();

    debugPrint('PDF Finansal Özet: Filtreleme başlıyor...');

    final periodPayments = filter.filterPayments(
      allPayments,
      periodStart,
      periodEnd,
    );
    final periodAdvances = filter.filterAdvances(
      allAdvances,
      periodStart,
      periodEnd,
    );
    final periodExpenses = filter.filterExpenses(
      allExpenses,
      periodStart,
      periodEnd,
    );

    final totals = calculator.calculateTotals(
      periodPayments,
      periodAdvances,
      periodExpenses,
    );
    final categoryTotals = calculator.calculateCategoryTotals(periodExpenses);

    final headerBuilder = SummaryHeaderBuilder(base);
    final statsBuilder = SummaryStatsBuilder(base);
    final chartBuilder = SummaryChartBuilder(base);
    final tableBuilder = SummaryTableBuilder(base);

    pages.add(
      headerBuilder.buildHeader(
        periodTitle: periodTitle,
        periodStart: periodStart,
        periodEnd: periodEnd,
      ),
    );
    pages.add(pw.SizedBox(height: 30));

    pages.add(
      statsBuilder.buildExecutiveDashboard(
        totalPayments: totals['totalPayments']!,
        totalAdvances: totals['totalAdvances']!,
        totalExpenses: totals['totalExpenses']!,
      ),
    );
    pages.add(pw.SizedBox(height: 30));

    pages.add(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: chartBuilder.buildExpenseDistributionCard(
              totalPayments: totals['totalPayments']!,
              totalAdvances: totals['totalAdvances']!,
              totalExpenses: totals['totalExpenses']!,
              totalSpending: totals['totalSpending']!,
            ),
          ),
          pw.SizedBox(width: 24),
          pw.Expanded(
            child: statsBuilder.buildAdvanceStatusCard(
              totalAdvances: totals['totalAdvances']!,
              deductedAdvances: totals['deductedAdvances']!,
              pendingAdvances: totals['pendingAdvances']!,
            ),
          ),
        ],
      ),
    );
    pages.add(pw.SizedBox(height: 30));

    final categoriesCard = tableBuilder.buildExpenseCategoriesCard(
      categoryTotals: categoryTotals,
      totalExpenses: totals['totalExpenses']!,
    );
    if (categoriesCard != null) {
      pages.add(categoriesCard);
    }

    pages.add(pw.SizedBox(height: 40));
    pages.add(headerBuilder.buildFooter());

    return pages;
  }

  Future<File> _savePdf(
    pw.Document pdf,
    String periodTitle,
    String? outputDirectory,
  ) async {
    final outputPath = outputDirectory ?? (await getTemporaryDirectory()).path;
    final file = File(
      '$outputPath/${periodTitle.replaceAll(' ', '_')}_finansal_ozet.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    await _base.openPdf(file);
    return file;
  }
}
