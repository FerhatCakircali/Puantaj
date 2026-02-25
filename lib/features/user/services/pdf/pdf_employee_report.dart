import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'pdf_base_service.dart';
import '../../../../../models/employee.dart';
import '../../../../../models/attendance.dart';
import '../../../../../models/payment.dart';
import 'employee_report/builders/employee_info_builder.dart';
import 'employee_report/builders/attendance_summary_builder.dart';
import 'employee_report/builders/payment_info_builder.dart';
import 'employee_report/builders/attendance_details_builder.dart';

/// Çalışan raporu PDF oluşturma servisi - Modüler tasarım
class PdfEmployeeReportService {
  final PdfBaseService _base = PdfBaseService();

  Future<File> generate({
    required Employee employee,
    required List<Attendance> attendances,
    required List<Payment> payments,
    String? outputDirectory,
  }) async {
    await _base.loadFonts();

    final allDays = _buildAllDays(employee, attendances);
    final pdf = pw.Document(theme: _base.fontsLoaded ? _base.pdfTheme : null);

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
            EmployeeInfoBuilder.build(employee, headerStyle),
            pw.SizedBox(height: 20),
            AttendanceSummaryBuilder.build(employee, allDays, headerStyle),
            pw.SizedBox(height: 20),
            PaymentInfoBuilder.build(allDays, payments, headerStyle),
            pw.SizedBox(height: 20),
            ...AttendanceDetailsBuilder.build(allDays, headerStyle),
            pw.SizedBox(height: 10),
            _buildFooter(employee),
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

  pw.Widget _buildFooter(Employee employee) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Bu rapor ${employee.name} için oluşturulmuştur.'),
              pw.Text('Oluşturma Tarihi: ${dateFormat.format(DateTime.now())}'),
            ],
          ),
        ],
      ),
    );
  }
}
