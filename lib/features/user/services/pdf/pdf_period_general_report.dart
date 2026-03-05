import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'pdf_base_service.dart';
import '../../../../../models/employee.dart';
import '../../../../../models/attendance.dart';
import '../../../../../models/payment.dart';
import 'dart:typed_data';
import 'helpers/pdf_styles.dart';
import 'helpers/pdf_svg_icons.dart';
import 'helpers/pdf_general_summary_helper.dart';
import 'helpers/pdf_general_table_helper.dart';
import 'helpers/pdf_expense_helper.dart';
import 'pdf_report_utils.dart';
import '../../../../../models/expense.dart';
import '../../../../../models/advance.dart';

/// Genel dönem raporu PDF oluşturma servisi
/// Orchestrator pattern kullanarak helper sınıflarını koordine eder
class PdfPeriodGeneralReportService {
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
    // Font yükleme
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

    // Geçici base service oluştur
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
        margin: const pw.EdgeInsets.all(32),
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
        margin: const pw.EdgeInsets.all(32),
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

    final pages = <pw.Widget>[];

    // 1. Premium gradient başlık - Finansal Özet ile aynı format
    pages.add(
      pw.Container(
        padding: styles.largePadding,
        decoration: styles.premiumHeaderDecoration,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('GENEL DÖNEM RAPORU', style: styles.mainTitleStyle),
                pw.SizedBox(height: 6),
                pw.Text(
                  periodTitle,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    font: base.boldFont,
                  ),
                ),
              ],
            ),
            // Beyaz kutu - RAPOR DÖNEMİ
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: pw.BoxDecoration(color: PdfColors.white),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'RAPOR DÖNEMİ',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfStyles.neutralColor,
                      font: base.boldFont,
                      letterSpacing: 1.0,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${PdfReportUtils.dateFormat.format(periodStart)} - ${PdfReportUtils.dateFormat.format(periodEnd)}',
                    style: pw.TextStyle(
                      fontSize: 11,
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
      ),
    );
    pages.add(pw.SizedBox(height: 16));

    // 2. Ana özet tablosu (TÜM ÇALIŞANLAR)
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
    pages.add(pw.SizedBox(height: 16));

    // 3. Genel masraf özeti (yöneticinin masrafları)
    if (expenses.isNotEmpty) {
      pages.add(
        PdfExpenseHelper.buildExpenseInfo(
          expenses,
          periodStart,
          periodEnd,
          styles,
        ),
      );
      pages.add(pw.SizedBox(height: 16));
    }

    // 4. Finansal özet kartı
    pages.add(
      _buildFinancialSummaryCard(
        employees: employees,
        allPayments: allPayments,
        allAdvances: allAdvances,
        expenses: expenses,
        periodStart: periodStart,
        periodEnd: periodEnd,
        styles: styles,
        base: base,
      ),
    );

    // Footer - Standart (Ortalanmış)
    pages.add(pw.SizedBox(height: 16));
    pages.add(
      pw.Container(
        padding: const pw.EdgeInsets.only(top: 16),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
          ),
        ),
        child: pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'Rapor Oluşturma Tarihi: ${PdfReportUtils.dateFormat.format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 9, color: PdfStyles.neutralColor),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Sayfa 1',
                style: pw.TextStyle(fontSize: 9, color: PdfStyles.neutralColor),
              ),
            ],
          ),
        ),
      ),
    );

    return pages;
  }

  /// Finansal özet kartı oluştur (modern tasarım)
  pw.Widget _buildFinancialSummaryCard({
    required List<Employee> employees,
    required List<List<Payment>> allPayments,
    required List<List<Advance>> allAdvances,
    required List<Expense> expenses,
    required DateTime periodStart,
    required DateTime periodEnd,
    required PdfStyles styles,
    required PdfBaseService base,
  }) {
    // Toplam ödemeler (dönem içi)
    double totalPayments = 0;
    for (var payments in allPayments) {
      totalPayments += payments
          .where((p) => _isInPeriod(p.paymentDate, periodStart, periodEnd))
          .fold<double>(0, (sum, p) => sum + p.amount);
    }

    // Toplam avanslar (dönem içi)
    double totalAdvances = 0;
    double deductedAdvances = 0;
    double pendingAdvances = 0;
    for (var advances in allAdvances) {
      final periodAdvances = advances
          .where((a) => _isInPeriod(a.advanceDate, periodStart, periodEnd))
          .toList();

      totalAdvances += periodAdvances.fold<double>(
        0,
        (sum, a) => sum + a.amount,
      );
      deductedAdvances += periodAdvances
          .where((a) => a.isDeducted)
          .fold<double>(0, (sum, a) => sum + a.amount);
      pendingAdvances += periodAdvances
          .where((a) => !a.isDeducted)
          .fold<double>(0, (sum, a) => sum + a.amount);
    }

    // Toplam masraflar (dönem içi)
    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    // Toplam gider
    final totalSpending = totalPayments + totalAdvances + totalExpenses;

    return pw.Container(
      padding: styles.standardPadding,
      decoration: styles.primaryCardDecoration,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'FİNANSAL ÖZET',
            style: pw.TextStyle(
              font: base.boldFont,
              fontSize: 16,
              color: PdfStyles.primaryColor,
            ),
          ),
          pw.SizedBox(height: 12),

          // İstatistik kartları (grid)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                PdfSvgIcons.users,
                'Çalışan',
                '${employees.length}',
                PdfStyles.primaryColor,
                styles,
                base,
              ),
              pw.SizedBox(width: 8),
              _buildStatCard(
                PdfSvgIcons.money,
                'Ödemeler',
                PdfReportUtils.formatCurrency(totalPayments),
                PdfStyles.successColor,
                styles,
                base,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                PdfSvgIcons.handMoney,
                'Avanslar',
                PdfReportUtils.formatCurrency(totalAdvances),
                PdfStyles.warningColor,
                styles,
                base,
              ),
              pw.SizedBox(width: 8),
              _buildStatCard(
                PdfSvgIcons.shopping,
                'Masraflar',
                PdfReportUtils.formatCurrency(totalExpenses),
                PdfStyles.dangerColor,
                styles,
                base,
              ),
            ],
          ),
          pw.SizedBox(height: 12),

          // Avans detayları - Modern Bento Box (Yeşil/Turuncu Dots)
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border(
                top: pw.BorderSide(color: PdfStyles.warningColor, width: 3),
                left: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
                right: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
                bottom: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
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
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Row(
                      children: [
                        // Yeşil dot
                        pw.Container(
                          width: 6,
                          height: 6,
                          decoration: pw.BoxDecoration(
                            color: PdfStyles.successColor,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          'Düşülmüş Avans',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfStyles.darkColor,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      PdfReportUtils.formatCurrency(deductedAdvances),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfStyles.successColor,
                        font: base.boldFont,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Row(
                      children: [
                        // Turuncu dot
                        pw.Container(
                          width: 6,
                          height: 6,
                          decoration: pw.BoxDecoration(
                            color: PdfStyles.warningColor,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          'Bekleyen Avans',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfStyles.darkColor,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      PdfReportUtils.formatCurrency(pendingAdvances),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfStyles.warningColor,
                        font: base.boldFont,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Modern Toplam Gider Bandı - İnce, keskin köşeli, derin gölge
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 18,
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
                  'TOPLAM GİDER',
                  style: pw.TextStyle(
                    font: base.boldFont,
                    fontSize: 11,
                    color: PdfColors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.Text(
                  PdfReportUtils.formatCurrency(totalSpending),
                  style: pw.TextStyle(
                    font: base.boldFont,
                    fontSize: 16,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Küçük istatistik kartı oluştur (İkonsuz, Minimalist, Büyük Metinler)
  pw.Widget _buildStatCard(
    String iconSvg,
    String label,
    String value,
    PdfColor color,
    PdfStyles styles,
    PdfBaseService base,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: PdfStyles.borderColor, width: 0.5),
          boxShadow: [
            pw.BoxShadow(
              color: PdfColor.fromInt(0x0A000000),
              offset: const PdfPoint(0, 1),
              blurRadius: 4,
            ),
          ],
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfStyles.neutralColor,
                fontWeight: pw.FontWeight.bold,
                font: base.boldFont,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              value,
              style: pw.TextStyle(
                font: base.boldFont,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// PDF'i kaydeder (açmaz - ana thread'de açılacak)
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
    // openPdf çağrısı kaldırıldı - isolate içinde çalışmaz
    // Ana thread'de açılacak
    return file;
  }

  /// Tarihin dönem içinde olup olmadığını kontrol eder
  bool _isInPeriod(DateTime date, DateTime periodStart, DateTime periodEnd) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(
      periodStart.year,
      periodStart.month,
      periodStart.day,
    );
    final normalizedEnd = DateTime(
      periodEnd.year,
      periodEnd.month,
      periodEnd.day,
    );
    return !normalizedDate.isBefore(normalizedStart) &&
        !normalizedDate.isAfter(normalizedEnd);
  }
}
