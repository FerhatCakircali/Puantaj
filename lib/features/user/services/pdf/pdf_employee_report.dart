import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'pdf_base_service.dart';
import '../../../../../models/employee.dart';
import '../../../../../models/attendance.dart';
import '../../../../../models/payment.dart';
import '../../../../../models/advance.dart';
import 'employee_report/builders/employee_info_builder.dart';
import 'employee_report/builders/attendance_summary_builder.dart';
import 'employee_report/builders/payment_info_builder.dart';
import 'employee_report/builders/attendance_details_builder.dart';
import 'helpers/pdf_styles.dart';
import 'helpers/pdf_employee_report_table.dart';

/// Çalışan raporu PDF oluşturma servisi - Modüler tasarım
class PdfEmployeeReportService {
  final PdfBaseService _base = PdfBaseService();

  Future<File> generate({
    required Employee employee,
    required List<Attendance> attendances,
    required List<Payment> payments,
    required List<Advance> advances,
    String? outputDirectory,
  }) async {
    await _base.loadFonts();

    final allDays = _buildAllDays(employee, attendances);
    final pdf = pw.Document(theme: _base.fontsLoaded ? _base.pdfTheme : null);
    final styles = PdfStyles(_base);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Premium gradient header
            _buildPremiumHeader(styles),
            pw.SizedBox(height: 20),

            // Bento layout: Çalışan bilgileri ve Devam özeti yan yana
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: EmployeeInfoBuilder.build(employee, styles)),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: AttendanceSummaryBuilder.build(
                    employee,
                    allDays,
                    styles,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            PaymentInfoBuilder.build(allDays, payments, styles, _base.boldFont),
            pw.SizedBox(height: 16),
            // Avans bilgileri
            PdfEmployeeReportTable.buildAdvanceInfo(
              advances,
              employee.startDate,
              DateTime.now(),
              styles,
            ),
            pw.SizedBox(height: 16),
            ...AttendanceDetailsBuilder.build(allDays, styles),
          ];
        },
        footer: (pw.Context context) => _buildFooter(context),
      ),
    );

    final outputPath = outputDirectory ?? (await getTemporaryDirectory()).path;
    final file = File('$outputPath/${employee.name}_rapor.pdf');
    await file.writeAsBytes(await pdf.save());
    await _base.openPdf(file);
    return file;
  }

  List<Attendance> _buildAllDays(
    Employee employee,
    List<Attendance> attendances,
  ) {
    final allDays = <Attendance>[];
    DateTime currentDate = employee.startDate;

    while (!currentDate.isAfter(DateTime.now())) {
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

  /// Premium gradient header oluştur
  pw.Widget _buildPremiumHeader(PdfStyles styles) {
    return pw.Container(
      padding: styles.headerPadding,
      decoration: styles.premiumHeaderDecoration,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('ÇALIŞAN RAPORU', style: styles.mainTitleStyle),
              pw.SizedBox(height: 6),
              pw.Text(
                'Detaylı Performans ve Devam Analizi',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromInt(0xFFD1D5DB),
                  font: _base.baseFont,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: pw.BoxDecoration(color: PdfColors.white),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'RAPOR TARİHİ',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfStyles.neutralColor,
                    font: _base.baseFont,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  DateFormat('dd.MM.yyyy').format(DateTime.now()),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfStyles.primaryColor,
                    font: _base.boldFont,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Premium footer oluştur
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfStyles.borderColor, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Rapor Oluşturma: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfStyles.neutralColor,
              font: _base.baseFont,
            ),
          ),
          pw.Text(
            'Sayfa ${context.pageNumber}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfStyles.neutralColor,
              font: _base.baseFont,
            ),
          ),
        ],
      ),
    );
  }
}
