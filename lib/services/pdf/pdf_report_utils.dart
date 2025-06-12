import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class PdfReportUtils {
  static final dateFormat = DateFormat('dd.MM.yyyy');
  static pw.Font? robotoFont;
  static pw.Font? robotoBoldFont;
  static pw.ThemeData? robotoTheme;

  static String formatDate(DateTime date) {
    return dateFormat.format(date);
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
          children:
              headers
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
            children:
                row
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
