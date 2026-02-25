import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'pdf_base_service.dart';
import '../../../../../models/employee.dart';
import '../../../../../models/attendance.dart';
import '../../../../../models/payment.dart';
import 'helpers/index.dart';

class PdfPeriodEmployeeReportService {
  final PdfBaseService _base = PdfBaseService();

  Future<File> generate({
    required Employee employee,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Attendance> attendances,
    required List<Payment> payments,
    required String periodTitle,
    void Function(double progress)? progressCallback,
    String? outputDirectory,
  }) async {
    await _base.loadFonts();

    // Tüm günleri hazırla
    final allDays = _prepareAllDays(
      employee,
      periodStart,
      periodEnd,
      attendances,
      progressCallback,
    );

    // PDF oluştur
    final pdf = pw.Document(theme: _base.fontsLoaded ? _base.pdfTheme : null);
    final styles = PdfStyles(_base);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          if (progressCallback != null) {
            progressCallback(0.75);
          }

          return [
            // Başlık
            PdfEmployeeReportHeader.buildTitle(periodTitle, styles),
            pw.SizedBox(height: 10),

            // Çalışan bilgileri
            PdfEmployeeReportHeader.buildEmployeeInfo(employee, styles),
            pw.SizedBox(height: 20),

            // Devam kayıtları özeti
            PdfEmployeeReportTable.buildAttendanceSummary(
              allDays,
              periodStart,
              periodEnd,
              styles,
            ),
            pw.SizedBox(height: 20),

            // Ödeme bilgileri
            PdfEmployeeReportTable.buildPaymentInfo(
              payments,
              allDays,
              periodStart,
              periodEnd,
              styles,
            ),
            pw.SizedBox(height: 20),

            // Tam gün çalışma kayıtları
            if (PdfEmployeeReportTable.buildAttendanceTable(
                  allDays,
                  AttendanceStatus.fullDay,
                  'TAM GÜN ÇALIŞMA KAYITLARI',
                  styles,
                ) !=
                null) ...[
              pw.SizedBox(height: 20),
              PdfEmployeeReportTable.buildAttendanceTable(
                allDays,
                AttendanceStatus.fullDay,
                'TAM GÜN ÇALIŞMA KAYITLARI',
                styles,
              )!,
            ],

            // Yarım gün çalışma kayıtları
            if (PdfEmployeeReportTable.buildAttendanceTable(
                  allDays,
                  AttendanceStatus.halfDay,
                  'YARIM GÜN ÇALIŞMA KAYITLARI',
                  styles,
                ) !=
                null) ...[
              pw.SizedBox(height: 20),
              PdfEmployeeReportTable.buildAttendanceTable(
                allDays,
                AttendanceStatus.halfDay,
                'YARIM GÜN ÇALIŞMA KAYITLARI',
                styles,
              )!,
            ],

            // Gelmediği günler
            if (PdfEmployeeReportTable.buildAttendanceTable(
                  allDays,
                  AttendanceStatus.absent,
                  'GELMEDİĞİ GÜNLER',
                  styles,
                ) !=
                null) ...[
              pw.SizedBox(height: 20),
              PdfEmployeeReportTable.buildAttendanceTable(
                allDays,
                AttendanceStatus.absent,
                'GELMEDİĞİ GÜNLER',
                styles,
              )!,
            ],

            // Footer
            pw.SizedBox(height: 10),
            PdfEmployeeReportFooter.buildFooter(employee),
          ];
        },
      ),
    );

    if (progressCallback != null) progressCallback(1.0);

    // PDF'i kaydet ve aç
    final outputPath = outputDirectory ?? (await getTemporaryDirectory()).path;
    final file = File(
      '$outputPath/${periodTitle.replaceAll(' ', '_')}_calisan_raporu.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    await _base.openPdf(file);

    return file;
  }

  /// Tüm günleri hazırla (devam kayıtları)
  List<Attendance> _prepareAllDays(
    Employee employee,
    DateTime periodStart,
    DateTime periodEnd,
    List<Attendance> attendances,
    void Function(double progress)? progressCallback,
  ) {
    final allDays = <Attendance>[];
    DateTime currentDate = periodStart.isAfter(employee.startDate)
        ? periodStart
        : employee.startDate;

    final totalDays = periodEnd.difference(currentDate).inDays + 1;
    int processedDays = 0;

    while (!currentDate.isAfter(periodEnd)) {
      final existingRecord = attendances.firstWhere(
        (a) =>
            a.date.year == currentDate.year &&
            a.date.month == currentDate.month &&
            a.date.day == currentDate.day,
        orElse: () => Attendance(
          userId: 0,
          workerId: employee.id,
          date: currentDate,
          status: AttendanceStatus.absent,
        ),
      );

      allDays.add(existingRecord);
      processedDays++;

      if (progressCallback != null && totalDays > 0) {
        progressCallback(processedDays / totalDays * 0.5);
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return allDays;
  }
}
