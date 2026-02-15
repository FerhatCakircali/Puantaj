import 'dart:io';
import '../models/attendance.dart';
import '../models/payment.dart';
import '../models/employee.dart';
import 'pdf/pdf_employee_terminated_report.dart';
import 'pdf/pdf_employee_report.dart';
import 'pdf/pdf_period_employee_report.dart';
import 'pdf/pdf_period_general_report.dart';
import 'package:open_file/open_file.dart';
import 'dart:typed_data';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  // Silinen çalışan için rapor
  Future<File> generateEmployeeTerminatedReport(
    Employee employee,
    List<Attendance> attendances,
    List<Payment> payments,
  ) {
    return PdfEmployeeTerminatedReportService().generate(
      employee: employee,
      attendances: attendances,
      payments: payments,
    );
  }

  // Çalışan raporu (Raporlar > Çalışan Raporu sekmesi)
  Future<File> generateEmployeeReport(
    Employee employee,
    List<Attendance> attendances,
    List<Payment> payments,
  ) {
    return PdfEmployeeReportService().generate(
      employee: employee,
      attendances: attendances,
      payments: payments,
    );
  }

  // Dönemsel rapor (çalışan seçili) - ilerleme destekli
  Future<File> generatePeriodEmployeeReportWithProgress({
    required Employee employee,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Attendance> attendances,
    required List<Payment> payments,
    required String periodTitle,
    void Function(double progress)? progressCallback,
    String? outputDirectory,
  }) {
    return PdfPeriodEmployeeReportService().generate(
      employee: employee,
      periodStart: periodStart,
      periodEnd: periodEnd,
      attendances: attendances,
      payments: payments,
      periodTitle: periodTitle,
      progressCallback: progressCallback,
      outputDirectory: outputDirectory,
    );
  }

  // Dönemsel genel rapor (tüm çalışanlar)
  Future<File> generatePeriodGeneralReport({
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
    return PdfPeriodGeneralReportService().generate(
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
  }

  Future<void> openPdf(File file) async {
    await OpenFile.open(file.path);
  }
}
