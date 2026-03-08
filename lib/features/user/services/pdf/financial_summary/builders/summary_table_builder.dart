import 'package:pdf/widgets.dart' as pw;
import '../../pdf_base_service.dart';
import '../../helpers/pdf_styles.dart';
import '../../pdf_report_utils.dart';
import '../../../../../../models/expense.dart';

/// Finansal özet tablo bileşenlerini oluşturur
class SummaryTableBuilder {
  final PdfBaseService base;
  final PdfStyles styles;

  SummaryTableBuilder(this.base) : styles = PdfStyles(base);

  /// Masraf kategorileri kartını oluşturur
  pw.Widget? buildExpenseCategoriesCard({
    required Map<ExpenseCategory, double> categoryTotals,
    required double totalExpenses,
  }) {
    if (categoryTotals.isEmpty) return null;

    final sortedCategories = categoryTotals.keys.toList()
      ..sort((a, b) => categoryTotals[b]!.compareTo(categoryTotals[a]!));

    return pw.Container(
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
              child: _buildCategoryProgressRow(
                PdfReportUtils.getCategoryName(category),
                amount,
                totalExpenses,
              ),
            );
          }),
        ],
      ),
    );
  }

  pw.Widget _buildCategoryProgressRow(
    String label,
    double amount,
    double total,
  ) {
    final percentage = total > 0 ? (amount / total) * 100 : 0.0;
    final progressWidth = percentage / 100;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
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
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(
              child: pw.Container(
                height: 4,
                child: pw.Stack(
                  children: [
                    pw.Container(
                      height: 4,
                      decoration: pw.BoxDecoration(color: PdfStyles.lightBg),
                    ),
                    pw.Container(
                      height: 4,
                      width: double.infinity,
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: (progressWidth * 100).toInt(),
                            child: pw.Container(
                              decoration: pw.BoxDecoration(
                                color: PdfStyles.primaryColor,
                              ),
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
                color: PdfStyles.primaryColor,
                font: base.boldFont,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
