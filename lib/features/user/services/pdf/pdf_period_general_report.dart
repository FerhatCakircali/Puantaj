import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'pdf_base_service.dart';
import '../../../../../models/employee.dart';
import '../../../../../models/attendance.dart';
import '../../../../../models/payment.dart';
import 'dart:typed_data';
import 'helpers/pdf_styles.dart';
import 'helpers/pdf_general_summary_helper.dart';
import 'helpers/pdf_general_table_helper.dart';
import 'helpers/pdf_general_detail_helper.dart';

/// Genel dönem raporu PDF oluşturma servisi
/// Orchestrator pattern kullanarak helper sınıflarını koordine eder
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
    // Font yükleme
    if (robotoFontBytes != null && robotoBoldFontBytes != null) {
      return _generateWithCustomFonts(
        periodTitle: periodTitle,
        periodStart: periodStart,
        periodEnd: periodEnd,
        employees: employees,
        allAttendances: allAttendances,
        allPayments: allPayments,
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
        employees: employees,
        allAttendances: allAttendances,
        allPayments: allPayments,
        outputDirectory: outputDirectory,
      );
    }
  }

  /// Custom fontlarla PDF oluşturur
  Future<File> _generateWithCustomFonts({
    required String periodTitle,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Employee> employees,
    required List<List<Attendance>> allAttendances,
    required List<List<Payment>> allPayments,
    String? outputDirectory,
    required Uint8List robotoFontBytes,
    required Uint8List robotoBoldFontBytes,
  }) async {
    final baseFont = pw.Font.ttf(robotoFontBytes.buffer.asByteData());
    final boldFont = pw.Font.ttf(robotoBoldFontBytes.buffer.asByteData());
    final pdfTheme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);
    final pdf = pw.Document(theme: pdfTheme);

    // Geçici base service oluştur
    final tempBase = PdfBaseService();
    tempBase.baseFont = baseFont;
    tempBase.boldFont = boldFont;

    final pages = _buildReportPages(
      base: tempBase,
      periodTitle: periodTitle,
      periodStart: periodStart,
      periodEnd: periodEnd,
      employees: employees,
      allAttendances: allAttendances,
      allPayments: allPayments,
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
    required List<Employee> employees,
    required List<List<Attendance>> allAttendances,
    required List<List<Payment>> allPayments,
    String? outputDirectory,
  }) async {
    final pdf = pw.Document(theme: _base.fontsLoaded ? _base.pdfTheme : null);

    final pages = _buildReportPages(
      base: _base,
      periodTitle: periodTitle,
      periodStart: periodStart,
      periodEnd: periodEnd,
      employees: employees,
      allAttendances: allAttendances,
      allPayments: allPayments,
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

  /// Rapor sayfalarını oluşturur (orchestrator)
  List<pw.Widget> _buildReportPages({
    required PdfBaseService base,
    required String periodTitle,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Employee> employees,
    required List<List<Attendance>> allAttendances,
    required List<List<Payment>> allPayments,
  }) {
    final styles = PdfStyles(base);
    final summaryHelper = PdfGeneralSummaryHelper(styles);
    final tableHelper = PdfGeneralTableHelper(styles, summaryHelper);
    final detailHelper = PdfGeneralDetailHelper(styles);

    final pages = <pw.Widget>[];

    // 1. Başlık ve tarih aralığı
    pages.addAll(
      summaryHelper.buildHeader(
        periodTitle: periodTitle,
        periodStart: periodStart,
        periodEnd: periodEnd,
      ),
    );

    // 2. Ana özet tablosu
    pages.add(
      tableHelper.buildSummaryTable(
        employees: employees,
        allAttendances: allAttendances,
        allPayments: allPayments,
        periodStart: periodStart,
        periodEnd: periodEnd,
      ),
    );
    pages.add(pw.SizedBox(height: 30));

    // 3. Her çalışan için detaylı bilgiler
    for (int i = 0; i < employees.length; i++) {
      final employee = employees[i];
      final attendances = allAttendances[i];
      final payments = allPayments[i];

      // Tüm günleri oluştur
      final allDays = _generateAllDays(
        employee: employee,
        attendances: attendances,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      // Çalışan bilgileri kartı
      pages.add(detailHelper.buildEmployeeInfoCard(employee));
      pages.add(pw.SizedBox(height: 20));

      // Devam kayıtları özet kartı
      pages.add(
        detailHelper.buildAttendanceSummaryCard(
          allDays: allDays,
          periodStart: periodStart,
          periodEnd: periodEnd,
        ),
      );
      pages.add(pw.SizedBox(height: 20));

      // Ödeme bilgileri kartı
      pages.add(
        detailHelper.buildPaymentInfoCard(
          payments: payments,
          allDays: allDays,
          periodStart: periodStart,
          periodEnd: periodEnd,
        ),
      );

      // Detaylı devam kayıtları tabloları
      _addAttendanceDetailTables(
        pages: pages,
        allDays: allDays,
        detailHelper: detailHelper,
      );

      // Footer
      pages.add(pw.SizedBox(height: 10));
      pages.add(detailHelper.buildReportFooter(employee.name));

      // Sayfa sonu (son çalışan hariç)
      if (i < employees.length - 1) {
        pages.add(pw.NewPage());
      }
    }

    return pages;
  }

  /// Tüm günleri oluşturur (devam kayıtları + eksik günler)
  List<Attendance> _generateAllDays({
    required Employee employee,
    required List<Attendance> attendances,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final allDays = <Attendance>[];
    DateTime currentDate = periodStart.isAfter(employee.startDate)
        ? periodStart
        : employee.startDate;

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
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return allDays;
  }

  /// Detaylı devam kayıtları tablolarını ekler
  void _addAttendanceDetailTables({
    required List<pw.Widget> pages,
    required List<Attendance> allDays,
    required PdfGeneralDetailHelper detailHelper,
  }) {
    // Tam gün çalışma kayıtları
    final fullDays = allDays
        .where((a) => a.status == AttendanceStatus.fullDay)
        .toList();
    if (fullDays.isNotEmpty) {
      pages.add(pw.SizedBox(height: 20));
      pages.add(
        detailHelper.buildAttendanceDetailTable(
          title: 'TAM GÜN ÇALIŞMA KAYITLARI',
          attendances: fullDays,
        ),
      );
    }

    // Yarım gün çalışma kayıtları
    final halfDays = allDays
        .where((a) => a.status == AttendanceStatus.halfDay)
        .toList();
    if (halfDays.isNotEmpty) {
      pages.add(pw.SizedBox(height: 20));
      pages.add(
        detailHelper.buildAttendanceDetailTable(
          title: 'YARIM GÜN ÇALIŞMA KAYITLARI',
          attendances: halfDays,
        ),
      );
    }

    // Gelmediği günler
    final absentDays = allDays
        .where((a) => a.status == AttendanceStatus.absent)
        .toList();
    if (absentDays.isNotEmpty) {
      pages.add(pw.SizedBox(height: 20));
      pages.add(
        detailHelper.buildAttendanceDetailTable(
          title: 'GELMEDİĞİ GÜNLER',
          attendances: absentDays,
        ),
      );
    }
  }

  /// PDF'i kaydeder ve açar
  Future<File> _savePdf(
    pw.Document pdf,
    String periodTitle,
    String? outputDirectory,
  ) async {
    final outputPath = outputDirectory ?? (await getTemporaryDirectory()).path;
    final file = File(
      '$outputPath/${periodTitle.replaceAll(' ', '_')}_genel_rapor.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    await _base.openPdf(file);
    return file;
  }
}
