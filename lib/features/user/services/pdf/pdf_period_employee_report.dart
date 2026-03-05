import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'pdf_base_service.dart';
import '../../../../../models/employee.dart';
import '../../../../../models/attendance.dart';
import '../../../../../models/payment.dart';
import '../../../../../models/advance.dart';
import 'helpers/index.dart';
import 'pdf_report_utils.dart';

class PdfPeriodEmployeeReportService {
  final PdfBaseService _base = PdfBaseService();

  Future<File> generate({
    required Employee employee,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Attendance> attendances,
    required List<Payment> payments,
    required List<Advance> advances,
    required String periodTitle,
    void Function(double progress)? progressCallback,
    String? outputDirectory,
  }) async {
    if (progressCallback != null) progressCallback(0.1);

    await _base.loadFonts();

    if (progressCallback != null) progressCallback(0.2);

    // Tüm günleri hazırla
    final allDays = _prepareAllDays(
      employee,
      periodStart,
      periodEnd,
      attendances,
      progressCallback,
    );

    if (progressCallback != null) progressCallback(0.6);

    // PDF oluştur
    final pdf = pw.Document(theme: _base.fontsLoaded ? _base.pdfTheme : null);
    final styles = PdfStyles(_base);

    if (progressCallback != null) progressCallback(0.7);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          if (progressCallback != null) {
            progressCallback(0.8);
          }

          return [
            // Premium gradient başlık - Genel raporla aynı format
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
                      pw.Text(
                        'DÖNEMSEL ÇALIŞAN RAPORU',
                        style: styles.mainTitleStyle,
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        periodTitle,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          font: _base.boldFont,
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
                            font: _base.boldFont,
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
                            font: _base.boldFont,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Çalışan bilgileri
            PdfEmployeeReportHeader.buildEmployeeInfo(employee, styles),
            pw.SizedBox(height: 16),

            // Devam kayıtları özeti
            PdfEmployeeReportTable.buildAttendanceSummary(
              allDays,
              periodStart,
              periodEnd,
              styles,
            ),
            pw.SizedBox(height: 16),

            // Ödeme bilgileri
            PdfEmployeeReportTable.buildPaymentInfo(
              payments,
              allDays,
              periodStart,
              periodEnd,
              styles,
            ),
            pw.SizedBox(height: 16),

            // Avans bilgileri
            PdfEmployeeReportTable.buildAdvanceInfo(
              advances,
              periodStart,
              periodEnd,
              styles,
            ),
            pw.SizedBox(height: 16),

            // Tam gün çalışma kayıtları
            if (PdfEmployeeReportTable.buildAttendanceTable(
                  allDays,
                  AttendanceStatus.fullDay,
                  'TAM GÜN ÇALIŞMA KAYITLARI',
                  styles,
                ) !=
                null) ...[
              PdfEmployeeReportTable.buildAttendanceTable(
                allDays,
                AttendanceStatus.fullDay,
                'TAM GÜN ÇALIŞMA KAYITLARI',
                styles,
              )!,
              pw.SizedBox(height: 16),
            ],

            // Yarım gün çalışma kayıtları
            if (PdfEmployeeReportTable.buildAttendanceTable(
                  allDays,
                  AttendanceStatus.halfDay,
                  'YARIM GÜN ÇALIŞMA KAYITLARI',
                  styles,
                ) !=
                null) ...[
              PdfEmployeeReportTable.buildAttendanceTable(
                allDays,
                AttendanceStatus.halfDay,
                'YARIM GÜN ÇALIŞMA KAYITLARI',
                styles,
              )!,
              pw.SizedBox(height: 16),
            ],

            // Gelmediği günler
            if (PdfEmployeeReportTable.buildAttendanceTable(
                  allDays,
                  AttendanceStatus.absent,
                  'GELMEDİĞİ GÜNLER',
                  styles,
                ) !=
                null) ...[
              PdfEmployeeReportTable.buildAttendanceTable(
                allDays,
                AttendanceStatus.absent,
                'GELMEDİĞİ GÜNLER',
                styles,
              )!,
            ],
          ];
        },
        footer: (pw.Context context) => _buildFooter(context),
      ),
    );

    if (progressCallback != null) progressCallback(0.9);

    // PDF'i kaydet ve aç
    final outputPath = outputDirectory ?? (await getTemporaryDirectory()).path;
    final file = File(
      '$outputPath/${periodTitle.replaceAll(' ', '_')}_calisan_raporu.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    if (progressCallback != null) progressCallback(0.95);

    await _base.openPdf(file);

    if (progressCallback != null) progressCallback(1.0);

    return file;
  }

  /// Premium footer oluştur
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
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
              'Sayfa ${context.pageNumber}',
              style: pw.TextStyle(fontSize: 9, color: PdfStyles.neutralColor),
            ),
          ],
        ),
      ),
    );
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
        // 0.2'den 0.5'e kadar progress (0.3 aralık)
        progressCallback(0.2 + (processedDays / totalDays * 0.3));
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return allDays;
  }
}
