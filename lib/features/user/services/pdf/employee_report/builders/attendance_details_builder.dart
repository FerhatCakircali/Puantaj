import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../../../../../../../models/attendance.dart';

/// Devam kayıtları detayları PDF widget'ı oluşturucu
class AttendanceDetailsBuilder {
  static List<pw.Widget> build(
    List<Attendance> allDays,
    pw.TextStyle headerStyle,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final widgets = <pw.Widget>[];

    // Tam gün kayıtları
    final fullDays = allDays
        .where((a) => a.status == AttendanceStatus.fullDay)
        .toList();
    if (fullDays.isNotEmpty) {
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('TAM GÜN ÇALIŞMA KAYITLARI', style: headerStyle),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Tarih', style: headerStyle),
                      ),
                    ],
                  ),
                  ...fullDays.map((attendance) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(dateFormat.format(attendance.date)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Yarım gün kayıtları
    final halfDays = allDays
        .where((a) => a.status == AttendanceStatus.halfDay)
        .toList();
    if (halfDays.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 20));
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('YARIM GÜN ÇALIŞMA KAYITLARI', style: headerStyle),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Tarih', style: headerStyle),
                      ),
                    ],
                  ),
                  ...halfDays.map((attendance) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(dateFormat.format(attendance.date)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Gelmediği günler
    final absentDays = allDays
        .where((a) => a.status == AttendanceStatus.absent)
        .toList();
    if (absentDays.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 20));
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('GELMEDİĞİ GÜNLER', style: headerStyle),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Tarih', style: headerStyle),
                      ),
                    ],
                  ),
                  ...absentDays.map((attendance) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(dateFormat.format(attendance.date)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }
}
