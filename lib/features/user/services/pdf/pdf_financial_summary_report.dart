import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'pdf_base_service.dart';
import '../../../../../models/payment.dart';
import '../../../../../models/advance.dart';
import '../../../../../models/expense.dart';
import 'dart:typed_data';
import 'helpers/pdf_styles.dart';
import 'pdf_report_utils.dart';

/// Finansal özet raporu PDF oluşturma servisi
class PdfFinancialSummaryReportService {
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
    // Font yükleme
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

  /// Custom fontlarla PDF oluşturur
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
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => pages,
      ),
    );

    return _savePdf(pdf, periodTitle, outputDirectory);
  }

  /// Rapor sayfalarını oluşturur
  List<pw.Widget> _buildReportPages({
    required PdfBaseService base,
    required String periodTitle,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Payment> allPayments,
    required List<Advance> allAdvances,
    required List<Expense> allExpenses,
  }) {
    final styles = PdfStyles(base);
    final pages = <pw.Widget>[];
    final dateFormat = PdfReportUtils.dateFormat;

    // Dönem filtreleme - Sadece dönem içindeki verileri al
    debugPrint('📊 PDF Finansal Özet: Filtreleme başlıyor...');
    debugPrint(
      '📊 Dönem: ${dateFormat.format(periodStart)} - ${dateFormat.format(periodEnd)}',
    );
    debugPrint(
      '📊 Gelen veriler: ${allPayments.length} ödeme, ${allAdvances.length} avans, ${allExpenses.length} masraf',
    );

    final periodPayments = _filterPaymentsByPeriod(
      allPayments,
      periodStart,
      periodEnd,
    );
    final periodAdvances = _filterAdvancesByPeriod(
      allAdvances,
      periodStart,
      periodEnd,
    );
    final periodExpenses = _filterExpensesByPeriod(
      allExpenses,
      periodStart,
      periodEnd,
    );

    debugPrint(
      '📊 Filtrelenmiş veriler: ${periodPayments.length} ödeme, ${periodAdvances.length} avans, ${periodExpenses.length} masraf',
    );

    // Hesaplamalar
    final totalPayments = periodPayments.fold<double>(
      0,
      (sum, p) => sum + p.amount,
    );
    final totalAdvances = periodAdvances.fold<double>(
      0,
      (sum, a) => sum + a.amount,
    );
    final deductedAdvances = periodAdvances
        .where((a) => a.isDeducted)
        .fold<double>(0, (sum, a) => sum + a.amount);
    final pendingAdvances = periodAdvances
        .where((a) => !a.isDeducted)
        .fold<double>(0, (sum, a) => sum + a.amount);
    final totalExpenses = periodExpenses.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );
    final totalSpending = totalPayments + totalAdvances + totalExpenses;

    // Kategori bazlı masraflar
    final categoryTotals = <ExpenseCategory, double>{};
    for (var expense in periodExpenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    // 1. Premium gradient başlık - Soft kurumsal geçiş
    pages.add(
      pw.Container(
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          gradient: pw.LinearGradient(
            colors: [
              PdfColor.fromInt(0xFF4F46E5), // Soft Indigo
              PdfColor.fromInt(0xFF6366F1), // Light Indigo
              PdfColor.fromInt(0xFF818CF8), // Very Light Indigo
            ],
            begin: pw.Alignment.topLeft,
            end: pw.Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            pw.BoxShadow(
              color: PdfColor.fromInt(0x334F46E5),
              offset: const PdfPoint(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('FİNANSAL ÖZET', style: styles.mainTitleStyle),
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
                    '${dateFormat.format(periodStart)} - ${dateFormat.format(periodEnd)}',
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
    pages.add(pw.SizedBox(height: 30));

    // 2. Executive Dashboard - 3 Minimalist Bento Cards
    pages.add(
      pw.Row(
        children: [
          pw.Expanded(
            child: _buildExecutiveCard(
              'Çalışan Ödemeleri',
              PdfReportUtils.formatCurrency(totalPayments),
              PdfStyles.successColor,
              styles,
              base,
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: _buildExecutiveCard(
              'Verilen Avanslar',
              PdfReportUtils.formatCurrency(totalAdvances),
              PdfStyles.warningColor,
              styles,
              base,
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: _buildExecutiveCard(
              'Masraflar',
              PdfReportUtils.formatCurrency(totalExpenses),
              PdfStyles.primaryColor,
              styles,
              base,
            ),
          ),
        ],
      ),
    );
    pages.add(pw.SizedBox(height: 30));

    // 3. Gider Dağılımı - Modern Progress Bars (Sol Sütun)
    pages.add(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Sol: Gider Dağılımı
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: styles.cardDecoration,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'GİDER DAĞILIMI',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfStyles.darkColor,
                      font: base.boldFont,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  _buildProgressRow(
                    'Çalışan Ödemeleri',
                    totalPayments,
                    totalSpending,
                    PdfStyles.successColor,
                    styles,
                    base,
                  ),
                  pw.SizedBox(height: 16),
                  _buildProgressRow(
                    'Verilen Avanslar',
                    totalAdvances,
                    totalSpending,
                    PdfStyles.warningColor,
                    styles,
                    base,
                  ),
                  pw.SizedBox(height: 16),
                  _buildProgressRow(
                    'Masraflar',
                    totalExpenses,
                    totalSpending,
                    PdfStyles.primaryColor,
                    styles,
                    base,
                  ),
                  pw.SizedBox(height: 20),
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
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            font: base.boldFont,
                            letterSpacing: 1.2,
                          ),
                        ),
                        pw.Text(
                          PdfReportUtils.formatCurrency(totalSpending),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            font: base.boldFont,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 24),
          // Sağ: Avans Durumu
          pw.Expanded(
            child: _buildAdvanceStatusCard(
              totalAdvances,
              deductedAdvances,
              pendingAdvances,
              styles,
              base,
            ),
          ),
        ],
      ),
    );
    pages.add(pw.SizedBox(height: 30));

    // 4. Masraf Kategorileri - Modern Progress Bars
    if (categoryTotals.isNotEmpty) {
      final sortedCategories = categoryTotals.keys.toList()
        ..sort((a, b) => categoryTotals[b]!.compareTo(categoryTotals[a]!));

      pages.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: styles.cardDecoration,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MASRAF KATEGORİLERİ',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfStyles.darkColor,
                  font: base.boldFont,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 20),
              ...sortedCategories.map((category) {
                final amount = categoryTotals[category]!;
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 16),
                  child: _buildProgressRow(
                    PdfReportUtils.getCategoryName(category),
                    amount,
                    totalExpenses,
                    PdfStyles.primaryColor,
                    styles,
                    base,
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    // Footer - Minimalist ve modern (Standart)
    pages.add(pw.SizedBox(height: 40));
    pages.add(
      pw.Container(
        padding: const pw.EdgeInsets.only(top: 16),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.5),
          ),
        ),
        child: pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'Rapor Tarihi: ${dateFormat.format(DateTime.now())}',
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

  /// Executive Dashboard Kartı (Minimalist Bento Box)
  pw.Widget _buildExecutiveCard(
    String label,
    String value,
    PdfColor accentColor,
    PdfStyles styles,
    PdfBaseService base,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border(
          top: pw.BorderSide(color: accentColor, width: 3),
          left: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
          right: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
          bottom: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
        ),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColor.fromInt(0x0A000000),
            offset: const PdfPoint(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfStyles.neutralColor,
              letterSpacing: 1.0,
              fontWeight: pw.FontWeight.bold,
              font: base.boldFont,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
              font: base.boldFont,
            ),
          ),
        ],
      ),
    );
  }

  /// Progress Row (Modern İlerleme Çubuğu ile - Minimalist)
  pw.Widget _buildProgressRow(
    String label,
    double amount,
    double total,
    PdfColor color,
    PdfStyles styles,
    PdfBaseService base,
  ) {
    final percentage = total > 0 ? (amount / total) * 100 : 0.0;
    final progressWidth = percentage / 100;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Label ve tutar - aynı hizada
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, color: PdfStyles.darkColor),
            ),
            pw.Text(
              PdfReportUtils.formatCurrency(amount),
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfStyles.darkColor,
                font: base.boldFont,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        // Progress bar ve yüzde - minimalist
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(
              child: pw.Container(
                height: 4,
                child: pw.Stack(
                  children: [
                    // Background bar
                    pw.Container(
                      height: 4,
                      decoration: pw.BoxDecoration(color: PdfStyles.lightBg),
                    ),
                    // Progress bar
                    pw.Container(
                      height: 4,
                      width: double.infinity,
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: (progressWidth * 100).toInt(),
                            child: pw.Container(
                              decoration: pw.BoxDecoration(color: color),
                            ),
                          ),
                          if (progressWidth < 1.0)
                            pw.Expanded(
                              flex: ((1 - progressWidth) * 100).toInt(),
                              child: pw.Container(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              '${percentage.toStringAsFixed(1)}%',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: color,
                font: base.boldFont,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Avans Durumu Kartı (Modern Bento Box - Yeşil/Turuncu Dots)
  pw.Widget _buildAdvanceStatusCard(
    double totalAdvances,
    double deductedAdvances,
    double pendingAdvances,
    PdfStyles styles,
    PdfBaseService base,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border(
          top: pw.BorderSide(color: PdfStyles.primaryColor, width: 3),
          left: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
          right: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
          bottom: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
        ),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColor.fromInt(0x0A000000),
            offset: const PdfPoint(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'AVANS DURUMU',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfStyles.darkColor,
              font: base.boldFont,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 20),
          _buildInfoRowWithDot(
            'Toplam Verilen',
            PdfReportUtils.formatCurrency(totalAdvances),
            PdfStyles.primaryColor,
            styles,
            base,
          ),
          pw.SizedBox(height: 16),
          _buildInfoRowWithDot(
            'Düşülmüş',
            PdfReportUtils.formatCurrency(deductedAdvances),
            PdfStyles.successColor,
            styles,
            base,
          ),
          pw.SizedBox(height: 16),
          _buildInfoRowWithDot(
            'Bekleyen',
            PdfReportUtils.formatCurrency(pendingAdvances),
            PdfStyles.warningColor,
            styles,
            base,
          ),
        ],
      ),
    );
  }

  /// Bilgi Satırı - Renkli Dot ile (Yeşil/Turuncu Vurgu)
  pw.Widget _buildInfoRowWithDot(
    String label,
    String value,
    PdfColor dotColor,
    PdfStyles styles,
    PdfBaseService base,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(
          children: [
            // Renkli dot (6x6px)
            pw.Container(
              width: 6,
              height: 6,
              decoration: pw.BoxDecoration(
                color: dotColor,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 11, color: PdfStyles.darkColor),
            ),
          ],
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: dotColor,
            font: base.boldFont,
          ),
        ),
      ],
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
      '$outputPath/${periodTitle.replaceAll(' ', '_')}_finansal_ozet.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    await _base.openPdf(file);
    return file;
  }

  /// Ödemeleri döneme göre filtrele
  List<Payment> _filterPaymentsByPeriod(
    List<Payment> payments,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    return payments.where((payment) {
      final paymentDate = DateTime(
        payment.paymentDate.year,
        payment.paymentDate.month,
        payment.paymentDate.day,
      );
      final startDate = DateTime(
        periodStart.year,
        periodStart.month,
        periodStart.day,
      );
      final endDate = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
      return !paymentDate.isBefore(startDate) && !paymentDate.isAfter(endDate);
    }).toList();
  }

  /// Avansları döneme göre filtrele
  List<Advance> _filterAdvancesByPeriod(
    List<Advance> advances,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    return advances.where((advance) {
      final advanceDate = DateTime(
        advance.advanceDate.year,
        advance.advanceDate.month,
        advance.advanceDate.day,
      );
      final startDate = DateTime(
        periodStart.year,
        periodStart.month,
        periodStart.day,
      );
      final endDate = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
      return !advanceDate.isBefore(startDate) && !advanceDate.isAfter(endDate);
    }).toList();
  }

  /// Masrafları döneme göre filtrele
  List<Expense> _filterExpensesByPeriod(
    List<Expense> expenses,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    return expenses.where((expense) {
      final expenseDate = DateTime(
        expense.expenseDate.year,
        expense.expenseDate.month,
        expense.expenseDate.day,
      );
      final startDate = DateTime(
        periodStart.year,
        periodStart.month,
        periodStart.day,
      );
      final endDate = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
      return !expenseDate.isBefore(startDate) && !expenseDate.isAfter(endDate);
    }).toList();
  }
}
