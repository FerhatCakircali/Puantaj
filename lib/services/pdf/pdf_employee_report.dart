import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import '../pdf/pdf_base_service.dart';
import '../pdf/pdf_report_utils.dart';
import '../../models/employee.dart';
import '../../models/attendance.dart';
import '../../models/payment.dart';

class PdfEmployeeReportService {
  final PdfBaseService _base = PdfBaseService();

  Future<File> generate({
    required Employee employee,
    required List<Attendance> attendances,
    required List<Payment> payments,
    String? outputDirectory,
  }) async {
    await _base.loadFonts();
    final allDays = <Attendance>[];
    DateTime currentDate = employee.startDate;
    while (!currentDate.isAfter(DateTime.now())) {
      final existingRecord = attendances.firstWhere(
        (a) =>
            a.date.year == currentDate.year &&
            a.date.month == currentDate.month &&
            a.date.day == currentDate.day,
        orElse:
            () => Attendance(
              userId: 0,
              workerId: employee.id,
              date: currentDate,
              status: AttendanceStatus.absent,
            ),
      );
      allDays.add(existingRecord);
      currentDate = currentDate.add(const Duration(days: 1));
    }
    final pdf = pw.Document(theme: _base.fontsLoaded ? _base.pdfTheme : null);
    final dateFormat = PdfReportUtils.dateFormat;
    final titleStyle = pw.TextStyle(
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
      font: _base.boldFont,
    );
    final headerStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 12,
      font: _base.boldFont,
    );
    final dataStyle = pw.TextStyle(fontSize: 10, font: _base.baseFont);
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Çalışan Raporu', style: titleStyle),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ÇALIŞAN BİLGİLERİ', style: headerStyle),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Ad Soyad:', style: headerStyle),
                      pw.Text(employee.name),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Unvan:', style: headerStyle),
                      pw.Text(employee.title),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Telefon:', style: headerStyle),
                      pw.Text(employee.phone),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('İşe Başlama Tarihi:', style: headerStyle),
                      pw.Text(dateFormat.format(employee.startDate)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DEVAM KAYITLARI ÖZETİ', style: headerStyle),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Değerlendirme Tarihi Aralığı:',
                        style: headerStyle,
                      ),
                      pw.Text(
                        '${dateFormat.format(employee.startDate)} - ${dateFormat.format(DateTime.now())}',
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Tam Gün Çalışma Sayısı:', style: headerStyle),
                      pw.Text(
                        '${allDays.where((a) => a.status == AttendanceStatus.fullDay).length} gün',
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Yarım Gün Çalışma Sayısı:', style: headerStyle),
                      pw.Text(
                        '${allDays.where((a) => a.status == AttendanceStatus.halfDay).length} gün',
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Geldiği Toplam Gün Sayısı:', style: headerStyle),
                      pw.Text(
                        '${(allDays.where((a) => a.status == AttendanceStatus.fullDay).length + (allDays.where((a) => a.status == AttendanceStatus.halfDay).length * 0.5)).toStringAsFixed(1)} gün',
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Gelmediği Gün Sayısı:', style: headerStyle),
                      pw.Text(
                        '${allDays.where((a) => a.status == AttendanceStatus.absent).length} gün',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ÖDEME BİLGİLERİ', style: headerStyle),
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                  pw.Text('Ödemeler:', style: headerStyle),
                  pw.SizedBox(height: 5),
                  payments.isEmpty
                      ? pw.Text('Henüz ödeme yapılmadı.')
                      : pw.Table(
                        border: pw.TableBorder.all(),
                        children: [
                          pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey300,
                            ),
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text('Tarih', style: headerStyle),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text('Tam Gün', style: headerStyle),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text('Yarım Gün', style: headerStyle),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text('Ödeme', style: headerStyle),
                              ),
                            ],
                          ),
                          ...payments.map((payment) {
                            return pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(
                                    dateFormat.format(payment.paymentDate),
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text('${payment.fullDays}'),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text('${payment.halfDays}'),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(
                                    '${payment.amount.toStringAsFixed(2)} ₺',
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Toplam Ödenen:', style: headerStyle),
                      pw.Text(
                        '${payments.fold<double>(0, (sum, payment) => sum + payment.amount).toStringAsFixed(2)} ₺',
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Ödenmeyen Gün Sayısı:', style: headerStyle),
                      pw.Text(
                        '${((allDays.where((a) => a.status == AttendanceStatus.fullDay).length + (allDays.where((a) => a.status == AttendanceStatus.halfDay).length * 0.5) - payments.fold<double>(0, (sum, payment) => sum + payment.fullDays + (payment.halfDays * 0.5)))).toStringAsFixed(1)} gün',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            if (allDays
                .where((a) => a.status == AttendanceStatus.fullDay)
                .isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
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
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey300,
                          ),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text('Tarih', style: headerStyle),
                            ),
                          ],
                        ),
                        ...allDays
                            .where((a) => a.status == AttendanceStatus.fullDay)
                            .map((attendance) {
                              return pw.TableRow(
                                children: [
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(5),
                                    child: pw.Text(
                                      dateFormat.format(attendance.date),
                                    ),
                                  ),
                                ],
                              );
                            })
                            .toList(),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            if (allDays
                .where((a) => a.status == AttendanceStatus.halfDay)
                .isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
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
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey300,
                          ),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text('Tarih', style: headerStyle),
                            ),
                          ],
                        ),
                        ...allDays
                            .where((a) => a.status == AttendanceStatus.halfDay)
                            .map((attendance) {
                              return pw.TableRow(
                                children: [
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(5),
                                    child: pw.Text(
                                      dateFormat.format(attendance.date),
                                    ),
                                  ),
                                ],
                              );
                            })
                            .toList(),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            if (allDays
                .where((a) => a.status == AttendanceStatus.absent)
                .isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
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
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey300,
                          ),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text('Tarih', style: headerStyle),
                            ),
                          ],
                        ),
                        ...allDays
                            .where((a) => a.status == AttendanceStatus.absent)
                            .map((attendance) {
                              return pw.TableRow(
                                children: [
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(5),
                                    child: pw.Text(
                                      dateFormat.format(attendance.date),
                                    ),
                                  ),
                                ],
                              );
                            })
                            .toList(),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            pw.SizedBox(height: 10),
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Bu rapor ${employee.name} için oluşturulmuştur.',
                      ),
                      pw.Text(
                        'Oluşturma Tarihi: ${dateFormat.format(DateTime.now())}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
    final outputPath = outputDirectory ?? (await getTemporaryDirectory()).path;
    final file = File('$outputPath/${employee.name}_rapor.pdf');
    await file.writeAsBytes(await pdf.save());
    await _base.openPdf(file);
    return file;
  }
}
