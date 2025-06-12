import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import '../pdf/pdf_base_service.dart';
import '../pdf/pdf_report_utils.dart';
import '../../models/employee.dart';
import '../../models/attendance.dart';
import '../../models/payment.dart';
import 'dart:math';
import 'dart:typed_data';

class PdfPeriodGeneralReportService {
  final PdfBaseService _base = PdfBaseService();

  Future<File> generate({
    required String periodTitle,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Employee> employees,
    required List<List<Attendance>> allAttendances,
    required List<List<Payment>> allPayments,
    String? outputDirectory,
    Uint8List? robotoFontBytes,
    Uint8List? robotoBoldFontBytes,
  }) async {
    if (robotoFontBytes != null && robotoBoldFontBytes != null) {
      final baseFont = pw.Font.ttf(robotoFontBytes.buffer.asByteData());
      final boldFont = pw.Font.ttf(robotoBoldFontBytes.buffer.asByteData());
      final pdfTheme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);
      final pdf = pw.Document(theme: pdfTheme);
      final dateFormat = PdfReportUtils.dateFormat;
      final titleStyle = pw.TextStyle(
        fontSize: 20,
        fontWeight: pw.FontWeight.bold,
        font: boldFont,
      );
      final headerStyle = pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 12,
        font: boldFont,
      );
      final dataStyle = pw.TextStyle(fontSize: 10, font: baseFont);
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            final List<pw.Widget> pages = [];

            pages.add(
              pw.Header(
                level: 1,
                child: pw.Text('GENEL ÖZET - $periodTitle', style: titleStyle),
              ),
            );
            pages.add(pw.SizedBox(height: 10));
            pages.add(
              pw.Text(
                'Değerlendirme Tarihi Aralığı: ${dateFormat.format(periodStart)} - ${dateFormat.format(periodEnd)}',
                style: headerStyle,
              ),
            );
            pages.add(pw.SizedBox(height: 10));

            List<List<String>> tableData = [];
            tableData.add([
              'Çalışan Adı Soyadı',
              'Unvanı',
              'Yapılan Toplam Ödeme',
              'Toplam Ödenmeyen Gün Sayısı',
            ]);

            double overallTotalPayment = 0;
            double overallTotalUnpaidDays = 0;

            for (int i = 0; i < employees.length; i++) {
              final employee = employees[i];
              final attendances = allAttendances[i];
              final payments = allPayments[i];

              double employeeTotalPayment = payments
                  .where((payment) {
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
                    final endDate = DateTime(
                      periodEnd.year,
                      periodEnd.month,
                      periodEnd.day,
                    );
                    return !paymentDate.isBefore(startDate) &&
                        !paymentDate.isAfter(endDate);
                  })
                  .fold(0.0, (sum, item) => sum + item.amount);
              overallTotalPayment += employeeTotalPayment;

              double totalPaidAttendanceDays = payments
                  .where((payment) {
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
                    final endDate = DateTime(
                      periodEnd.year,
                      periodEnd.month,
                      periodEnd.day,
                    );
                    return !paymentDate.isBefore(startDate) &&
                        !paymentDate.isAfter(endDate);
                  })
                  .fold(
                    0.0,
                    (sum, item) => sum + item.fullDays + (item.halfDays * 0.5),
                  );

              final filteredAttendances =
                  attendances.where((a) {
                    final attendanceDate = DateTime(
                      a.date.year,
                      a.date.month,
                      a.date.day,
                    );
                    final startDate = DateTime(
                      periodStart.year,
                      periodStart.month,
                      periodStart.day,
                    );
                    final endDate = DateTime(
                      periodEnd.year,
                      periodEnd.month,
                      periodEnd.day,
                    );
                    final employeeStartDate = DateTime(
                      employee.startDate.year,
                      employee.startDate.month,
                      employee.startDate.day,
                    );
                    return !attendanceDate.isBefore(startDate) &&
                        !attendanceDate.isAfter(endDate) &&
                        !attendanceDate.isBefore(employeeStartDate);
                  }).toList();

              double totalWorkedDaysInPeriod = filteredAttendances.fold(0.0, (
                sum,
                attendance,
              ) {
                if (attendance.status == AttendanceStatus.fullDay) {
                  return sum + 1.0;
                } else if (attendance.status == AttendanceStatus.halfDay) {
                  return sum + 0.5;
                }
                return sum;
              });

              double employeeTotalUnpaidDays =
                  totalWorkedDaysInPeriod - totalPaidAttendanceDays;
              if (employeeTotalUnpaidDays < 0) {
                employeeTotalUnpaidDays = 0;
              }
              overallTotalUnpaidDays += employeeTotalUnpaidDays;

              tableData.add([
                employee.name,
                employee.title,
                '${employeeTotalPayment.toStringAsFixed(2)} TL',
                '${max(0.0, employeeTotalUnpaidDays).toStringAsFixed(1)} gün',
              ]);
            }

            tableData.add([
              'TOPLAM',
              '',
              '${overallTotalPayment.toStringAsFixed(2)} TL',
              '${overallTotalUnpaidDays.toStringAsFixed(1)} gün',
            ]);

            pages.add(
              pw.Table.fromTextArray(
                headers: tableData.first,
                data: tableData.skip(1).toList(),
                border: pw.TableBorder.all(),
                headerStyle: headerStyle.copyWith(color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey700,
                ),
                cellPadding: const pw.EdgeInsets.all(5),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: dataStyle,
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
              ),
            );
            pages.add(pw.SizedBox(height: 30));

            for (int i = 0; i < employees.length; i++) {
              final employee = employees[i];
              final attendances = allAttendances[i];
              final payments = allPayments[i];
              final allDays = <Attendance>[];
              DateTime currentDate =
                  periodStart.isAfter(employee.startDate)
                      ? periodStart
                      : employee.startDate;
              while (!currentDate.isAfter(periodEnd)) {
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
              pages.add(
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
              );
              pages.add(pw.SizedBox(height: 20));
              pages.add(
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
                            '${dateFormat.format(periodStart)} - ${dateFormat.format(periodEnd)}',
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Tam Gün Çalışma Sayısı:',
                            style: headerStyle,
                          ),
                          pw.Text(
                            '${allDays.where((a) => a.status == AttendanceStatus.fullDay).length} gün',
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Yarım Gün Çalışma Sayısı:',
                            style: headerStyle,
                          ),
                          pw.Text(
                            '${allDays.where((a) => a.status == AttendanceStatus.halfDay).length} gün',
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Geldiği Toplam Gün Sayısı:',
                            style: headerStyle,
                          ),
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
              );
              pages.add(pw.SizedBox(height: 20));
              pages.add(
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
                                    child: pw.Text(
                                      'Tam Gün',
                                      style: headerStyle,
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(5),
                                    child: pw.Text(
                                      'Yarım Gün',
                                      style: headerStyle,
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(5),
                                    child: pw.Text('Ödeme', style: headerStyle),
                                  ),
                                ],
                              ),
                              ...payments
                                  .where((payment) {
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
                                    final endDate = DateTime(
                                      periodEnd.year,
                                      periodEnd.month,
                                      periodEnd.day,
                                    );
                                    return !paymentDate.isBefore(startDate) &&
                                        !paymentDate.isAfter(endDate);
                                  })
                                  .map((payment) {
                                    return pw.TableRow(
                                      children: [
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.all(5),
                                          child: pw.Text(
                                            dateFormat.format(
                                              payment.paymentDate,
                                            ),
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
                                  })
                                  .toList(),
                            ],
                          ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Toplam Ödenen:', style: headerStyle),
                          pw.Text(
                            '${payments.where((payment) {
                              final paymentDate = DateTime(payment.paymentDate.year, payment.paymentDate.month, payment.paymentDate.day);
                              final startDate = DateTime(periodStart.year, periodStart.month, periodStart.day);
                              final endDate = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
                              return !paymentDate.isBefore(startDate) && !paymentDate.isAfter(endDate);
                            }).fold<double>(0, (sum, payment) => sum + payment.amount).toStringAsFixed(2)} ₺',
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Ödenmeyen Gün Sayısı:', style: headerStyle),
                          pw.Text(
                            '${max(0.0, ((allDays.where((a) => a.status == AttendanceStatus.fullDay).length + (allDays.where((a) => a.status == AttendanceStatus.halfDay).length * 0.5) - payments.fold<double>(0, (sum, payment) => sum + payment.fullDays + (payment.halfDays * 0.5))))).toStringAsFixed(1)} gün',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
              if (allDays
                  .where((a) => a.status == AttendanceStatus.fullDay)
                  .isNotEmpty)
                pages.addAll([
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
                        pw.Text(
                          'TAM GÜN ÇALIŞMA KAYITLARI',
                          style: headerStyle,
                        ),
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
                                .where(
                                  (a) => a.status == AttendanceStatus.fullDay,
                                )
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
                ]);
              if (allDays
                  .where((a) => a.status == AttendanceStatus.halfDay)
                  .isNotEmpty)
                pages.addAll([
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
                        pw.Text(
                          'YARIM GÜN ÇALIŞMA KAYITLARI',
                          style: headerStyle,
                        ),
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
                                .where(
                                  (a) => a.status == AttendanceStatus.halfDay,
                                )
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
                ]);
              if (allDays
                  .where((a) => a.status == AttendanceStatus.absent)
                  .isNotEmpty)
                pages.addAll([
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
                                .where(
                                  (a) => a.status == AttendanceStatus.absent,
                                )
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
                ]);

              pages.add(pw.SizedBox(height: 10));
              pages.add(
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
              );
              if (i < employees.length - 1) {
                pages.add(pw.NewPage());
              }
            }
            return pages;
          },
        ),
      );
      final outputPath =
          outputDirectory ?? (await getTemporaryDirectory()).path;
      final file = File(
        '$outputPath/${periodTitle.replaceAll(' ', '_')}_genel_rapor.pdf',
      );
      await file.writeAsBytes(await pdf.save());
      await _base.openPdf(file);
      return file;
    } else {
      await _base.loadFonts();
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
            final List<pw.Widget> pages = [];

            pages.add(
              pw.Header(
                level: 1,
                child: pw.Text('GENEL ÖZET - $periodTitle', style: titleStyle),
              ),
            );
            pages.add(pw.SizedBox(height: 10));
            pages.add(
              pw.Text(
                'Değerlendirme Tarihi Aralığı: ${dateFormat.format(periodStart)} - ${dateFormat.format(periodEnd)}',
                style: headerStyle,
              ),
            );
            pages.add(pw.SizedBox(height: 10));

            List<List<String>> tableData = [];
            tableData.add([
              'Çalışan Adı Soyadı',
              'Unvanı',
              'Yapılan Toplam Ödeme',
              'Toplam Ödenmeyen Gün Sayısı',
            ]);

            double overallTotalPayment = 0;
            double overallTotalUnpaidDays = 0;

            for (int i = 0; i < employees.length; i++) {
              final employee = employees[i];
              final attendances = allAttendances[i];
              final payments = allPayments[i];

              double employeeTotalPayment = payments
                  .where((payment) {
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
                    final endDate = DateTime(
                      periodEnd.year,
                      periodEnd.month,
                      periodEnd.day,
                    );
                    return !paymentDate.isBefore(startDate) &&
                        !paymentDate.isAfter(endDate);
                  })
                  .fold(0.0, (sum, item) => sum + item.amount);
              overallTotalPayment += employeeTotalPayment;

              double totalPaidAttendanceDays = payments
                  .where((payment) {
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
                    final endDate = DateTime(
                      periodEnd.year,
                      periodEnd.month,
                      periodEnd.day,
                    );
                    return !paymentDate.isBefore(startDate) &&
                        !paymentDate.isAfter(endDate);
                  })
                  .fold(
                    0.0,
                    (sum, item) => sum + item.fullDays + (item.halfDays * 0.5),
                  );

              final filteredAttendances =
                  attendances.where((a) {
                    final attendanceDate = DateTime(
                      a.date.year,
                      a.date.month,
                      a.date.day,
                    );
                    final startDate = DateTime(
                      periodStart.year,
                      periodStart.month,
                      periodStart.day,
                    );
                    final endDate = DateTime(
                      periodEnd.year,
                      periodEnd.month,
                      periodEnd.day,
                    );
                    final employeeStartDate = DateTime(
                      employee.startDate.year,
                      employee.startDate.month,
                      employee.startDate.day,
                    );
                    return !attendanceDate.isBefore(startDate) &&
                        !attendanceDate.isAfter(endDate) &&
                        !attendanceDate.isBefore(employeeStartDate);
                  }).toList();

              double totalWorkedDaysInPeriod = filteredAttendances.fold(0.0, (
                sum,
                attendance,
              ) {
                if (attendance.status == AttendanceStatus.fullDay) {
                  return sum + 1.0;
                } else if (attendance.status == AttendanceStatus.halfDay) {
                  return sum + 0.5;
                }
                return sum;
              });

              double employeeTotalUnpaidDays =
                  totalWorkedDaysInPeriod - totalPaidAttendanceDays;
              if (employeeTotalUnpaidDays < 0) {
                employeeTotalUnpaidDays = 0;
              }
              overallTotalUnpaidDays += employeeTotalUnpaidDays;

              tableData.add([
                employee.name,
                employee.title,
                '${employeeTotalPayment.toStringAsFixed(2)} TL',
                '${max(0.0, employeeTotalUnpaidDays).toStringAsFixed(1)} gün',
              ]);
            }

            tableData.add([
              'TOPLAM',
              '',
              '${overallTotalPayment.toStringAsFixed(2)} TL',
              '${overallTotalUnpaidDays.toStringAsFixed(1)} gün',
            ]);

            pages.add(
              pw.Table.fromTextArray(
                headers: tableData.first,
                data: tableData.skip(1).toList(),
                border: pw.TableBorder.all(),
                headerStyle: headerStyle.copyWith(color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey700,
                ),
                cellPadding: const pw.EdgeInsets.all(5),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: dataStyle,
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
              ),
            );
            pages.add(pw.SizedBox(height: 30));

            for (int i = 0; i < employees.length; i++) {
              final employee = employees[i];
              final attendances = allAttendances[i];
              final payments = allPayments[i];
              final allDays = <Attendance>[];
              DateTime currentDate =
                  periodStart.isAfter(employee.startDate)
                      ? periodStart
                      : employee.startDate;
              while (!currentDate.isAfter(periodEnd)) {
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
              pages.add(
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
              );
              pages.add(pw.SizedBox(height: 20));
              pages.add(
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
                            '${dateFormat.format(periodStart)} - ${dateFormat.format(periodEnd)}',
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Tam Gün Çalışma Sayısı:',
                            style: headerStyle,
                          ),
                          pw.Text(
                            '${allDays.where((a) => a.status == AttendanceStatus.fullDay).length} gün',
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Yarım Gün Çalışma Sayısı:',
                            style: headerStyle,
                          ),
                          pw.Text(
                            '${allDays.where((a) => a.status == AttendanceStatus.halfDay).length} gün',
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Geldiği Toplam Gün Sayısı:',
                            style: headerStyle,
                          ),
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
              );
              pages.add(pw.SizedBox(height: 20));
              pages.add(
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
                                    child: pw.Text(
                                      'Tam Gün',
                                      style: headerStyle,
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(5),
                                    child: pw.Text(
                                      'Yarım Gün',
                                      style: headerStyle,
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(5),
                                    child: pw.Text('Ödeme', style: headerStyle),
                                  ),
                                ],
                              ),
                              ...payments
                                  .where((payment) {
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
                                    final endDate = DateTime(
                                      periodEnd.year,
                                      periodEnd.month,
                                      periodEnd.day,
                                    );
                                    return !paymentDate.isBefore(startDate) &&
                                        !paymentDate.isAfter(endDate);
                                  })
                                  .map((payment) {
                                    return pw.TableRow(
                                      children: [
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.all(5),
                                          child: pw.Text(
                                            dateFormat.format(
                                              payment.paymentDate,
                                            ),
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
                                  })
                                  .toList(),
                            ],
                          ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Toplam Ödenen:', style: headerStyle),
                          pw.Text(
                            '${payments.where((payment) {
                              final paymentDate = DateTime(payment.paymentDate.year, payment.paymentDate.month, payment.paymentDate.day);
                              final startDate = DateTime(periodStart.year, periodStart.month, periodStart.day);
                              final endDate = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
                              return !paymentDate.isBefore(startDate) && !paymentDate.isAfter(endDate);
                            }).fold<double>(0, (sum, payment) => sum + payment.amount).toStringAsFixed(2)} ₺',
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Ödenmeyen Gün Sayısı:', style: headerStyle),
                          pw.Text(
                            '${max(0.0, ((allDays.where((a) => a.status == AttendanceStatus.fullDay).length + (allDays.where((a) => a.status == AttendanceStatus.halfDay).length * 0.5) - payments.fold<double>(0, (sum, payment) => sum + payment.fullDays + (payment.halfDays * 0.5))))).toStringAsFixed(1)} gün',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
              if (allDays
                  .where((a) => a.status == AttendanceStatus.fullDay)
                  .isNotEmpty)
                pages.addAll([
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
                        pw.Text(
                          'TAM GÜN ÇALIŞMA KAYITLARI',
                          style: headerStyle,
                        ),
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
                                .where(
                                  (a) => a.status == AttendanceStatus.fullDay,
                                )
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
                ]);
              if (allDays
                  .where((a) => a.status == AttendanceStatus.halfDay)
                  .isNotEmpty)
                pages.addAll([
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
                        pw.Text(
                          'YARIM GÜN ÇALIŞMA KAYITLARI',
                          style: headerStyle,
                        ),
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
                                .where(
                                  (a) => a.status == AttendanceStatus.halfDay,
                                )
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
                ]);
              if (allDays
                  .where((a) => a.status == AttendanceStatus.absent)
                  .isNotEmpty)
                pages.addAll([
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
                                .where(
                                  (a) => a.status == AttendanceStatus.absent,
                                )
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
                ]);

              pages.add(pw.SizedBox(height: 10));
              pages.add(
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
              );
              if (i < employees.length - 1) {
                pages.add(pw.NewPage());
              }
            }
            return pages;
          },
        ),
      );
      final outputPath =
          outputDirectory ?? (await getTemporaryDirectory()).path;
      final file = File(
        '$outputPath/${periodTitle.replaceAll(' ', '_')}_genel_rapor.pdf',
      );
      await file.writeAsBytes(await pdf.save());
      await _base.openPdf(file);
      return file;
    }
  }
}
