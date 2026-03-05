import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../pdf_report_utils.dart';
import '../../../../../../models/expense.dart';
import 'pdf_styles.dart';

/// Masraf bilgileri için PDF helper
class PdfExpenseHelper {
  /// Masraf bilgileri kartı oluştur (geliştirilmiş analiz)
  static pw.Widget buildExpenseInfo(
    List<Expense> expenses,
    DateTime periodStart,
    DateTime periodEnd,
    PdfStyles styles,
  ) {
    final periodExpenses = _filterExpensesByPeriod(
      expenses,
      periodStart,
      periodEnd,
    );

    if (periodExpenses.isEmpty) {
      return pw.Container(
        padding: styles.standardPadding,
        decoration: styles.cardDecoration,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [pw.Text('MASRAF ANALİZİ', style: styles.headerStyle)],
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Bu dönemde masraf kaydı bulunmamaktadır.',
              style: styles.dataStyle,
            ),
          ],
        ),
      );
    }

    // Kategorilere göre grupla
    final categoryTotals = <ExpenseCategory, double>{};
    final categoryCounts = <ExpenseCategory, int>{};
    final categoryTypes = <ExpenseCategory, Set<String>>{};

    for (var expense in periodExpenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
      categoryCounts[expense.category] =
          (categoryCounts[expense.category] ?? 0) + 1;

      // Her kategori için türleri topla
      if (!categoryTypes.containsKey(expense.category)) {
        categoryTypes[expense.category] = <String>{};
      }
      categoryTypes[expense.category]!.add(expense.expenseType);
    }

    final totalExpenses = periodExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    // İstatistikler
    final stats = _calculateExpenseStats(periodExpenses, totalExpenses);

    return pw.Container(
      padding: styles.standardPadding,
      decoration: styles.warningCardDecoration,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('MASRAF ANALİZİ', style: styles.headerStyle),
          pw.SizedBox(height: 12),

          // Kategori dağılımı tablosu
          _buildExpenseTable(
            categoryTotals,
            categoryCounts,
            categoryTypes,
            totalExpenses,
            styles,
          ),
          pw.SizedBox(height: 12),

          // Harcama istatistikleri
          _buildExpenseStats(stats, styles),
          pw.SizedBox(height: 12),

          // Toplam masraf bandı
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfStyles.warningColor, PdfColor.fromInt(0xFFF59E0B)],
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Toplam Masraf',
                  style: pw.TextStyle(fontSize: 11, color: PdfColors.white),
                ),
                pw.Text(
                  PdfReportUtils.formatCurrency(totalExpenses),
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Masraf tablosu oluştur (yüzdelik oranlarla)
  static pw.Widget _buildExpenseTable(
    Map<ExpenseCategory, double> categoryTotals,
    Map<ExpenseCategory, int> categoryCounts,
    Map<ExpenseCategory, Set<String>> categoryTypes,
    double totalExpenses,
    PdfStyles styles,
  ) {
    final sortedCategories = categoryTotals.keys.toList()
      ..sort((a, b) => categoryTotals[b]!.compareTo(categoryTotals[a]!));

    return pw.TableHelper.fromTextArray(
      headers: ['Kategori', 'Tür', 'Adet', 'Tutar', 'Oran'],
      data: sortedCategories.map((category) {
        final amount = categoryTotals[category]!;
        final percentage = (amount / totalExpenses * 100).toStringAsFixed(1);
        final types = categoryTypes[category]?.join(', ') ?? '-';
        return [
          PdfReportUtils.getCategoryName(category),
          types,
          '${categoryCounts[category]}',
          PdfReportUtils.formatCurrency(amount),
          '%$percentage',
        ];
      }).toList(),
      border: pw.TableBorder.all(color: PdfStyles.borderColor),
      headerStyle: styles.whiteHeaderStyle,
      headerDecoration: styles.tableHeaderDecoration,
      headerAlignment: pw.Alignment.center,
      headerPadding: styles.cellPadding,
      cellStyle: styles.dataStyle,
      cellAlignment: pw.Alignment.center,
      cellPadding: styles.cellPadding,
      oddRowDecoration: styles.alternateRowDecoration,
      headerCount: 1,
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Kategori
        1: const pw.FlexColumnWidth(4), // Tür (daha da geniş)
        2: const pw.FlexColumnWidth(1), // Adet
        3: const pw.FlexColumnWidth(2), // Tutar
        4: const pw.FlexColumnWidth(1), // Oran
      },
    );
  }

  /// Harcama istatistikleri hesapla
  static Map<String, dynamic> _calculateExpenseStats(
    List<Expense> expenses,
    double totalExpenses,
  ) {
    if (expenses.isEmpty) {
      return {
        'dailyAverage': 0.0,
        'maxExpense': 0.0,
        'maxExpenseDate': null,
        'transactionCount': 0,
        'averageTransaction': 0.0,
      };
    }

    // Günlük ortalama
    final days = expenses.map((e) => e.expenseDate).toSet().length;
    final dailyAverage = totalExpenses / (days > 0 ? days : 1);

    // En büyük harcama
    final maxExpense = expenses
        .map((e) => e.amount)
        .reduce((a, b) => a > b ? a : b);
    final maxExpenseItem = expenses.firstWhere((e) => e.amount == maxExpense);

    // İşlem sayısı ve ortalama
    final transactionCount = expenses.length;
    final averageTransaction = totalExpenses / transactionCount;

    return {
      'dailyAverage': dailyAverage,
      'maxExpense': maxExpense,
      'maxExpenseDate': maxExpenseItem.expenseDate,
      'transactionCount': transactionCount,
      'averageTransaction': averageTransaction,
    };
  }

  /// Harcama istatistikleri widget'ı
  static pw.Widget _buildExpenseStats(
    Map<String, dynamic> stats,
    PdfStyles styles,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfStyles.borderColor, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Harcama İstatistikleri',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfStyles.darkColor,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Günlük Ortalama',
                PdfReportUtils.formatCurrency(stats['dailyAverage']),
                styles,
              ),
              _buildStatItem(
                'İşlem Sayısı',
                '${stats['transactionCount']} adet',
                styles,
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Ortalama İşlem',
                PdfReportUtils.formatCurrency(stats['averageTransaction']),
                styles,
              ),
              _buildStatItem(
                'En Büyük Harcama',
                PdfReportUtils.formatCurrency(stats['maxExpense']),
                styles,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// İstatistik item widget'ı
  static pw.Widget _buildStatItem(
    String label,
    String value,
    PdfStyles styles,
  ) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 8, color: PdfStyles.neutralColor),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfStyles.darkColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Masrafları döneme göre filtrele
  static List<Expense> _filterExpensesByPeriod(
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
