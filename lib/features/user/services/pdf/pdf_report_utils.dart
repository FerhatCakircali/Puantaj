import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../../../../models/expense.dart';

class PdfReportUtils {
  static final dateFormat = DateFormat('dd.MM.yyyy');
  static pw.Font? robotoFont;
  static pw.Font? robotoBoldFont;
  static pw.ThemeData? robotoTheme;

  static String formatDate(DateTime date) {
    return dateFormat.format(date);
  }

  /// Para formatı - Türk Lirası (123.456 ₺)
  static String formatCurrency(double amount) {
    final intAmount = amount.toInt();
    final str = intAmount.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }

    return '$buffer ₺';
  }

  /// Kategori adı
  static String getCategoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.malzeme:
        return 'Malzeme';
      case ExpenseCategory.ulasim:
        return 'Ulaşım';
      case ExpenseCategory.ekipman:
        return 'Ekipman';
      case ExpenseCategory.diger:
        return 'Diğer';
    }
  }

  static pw.Table buildTable({
    required List<String> headers,
    required List<List<String>> rows,
    pw.TextStyle? headerStyle,
    pw.TextStyle? cellStyle,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: headers
              .map(
                (h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(h, style: headerStyle),
                ),
              )
              .toList(),
        ),
        ...rows.map(
          (row) => pw.TableRow(
            children: row
                .map(
                  (cell) => pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(cell, style: cellStyle),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
