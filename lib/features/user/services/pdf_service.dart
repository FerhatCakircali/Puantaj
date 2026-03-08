import 'dart:io';
import '../../../models/attendance.dart';
import '../../../models/payment.dart';
import '../../../models/employee.dart';
import '../../../models/advance.dart';
import '../../../models/expense.dart';
import 'pdf/pdf_employee_terminated_report.dart';
import 'pdf/pdf_employee_report.dart';
import 'pdf/pdf_period_employee_report.dart';
import 'pdf/period_general/pdf_period_general_service.dart';
import 'pdf/pdf_financial_summary_report.dart';
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
    List<Advance> advances,
  ) {
    return PdfEmployeeTerminatedReportService().generate(
      employee: employee,
      attendances: attendances,
      payments: payments,
      advances: advances,
    );
  }

  // Çalışan raporu (Raporlar > Çalışan Raporu sekmesi)
  Future<File> generateEmployeeReport(
    Employee employee,
    List<Attendance> attendances,
    List<Payment> payments,
    List<Advance> advances,
  ) {
    return PdfEmployeeReportService().generate(
      employee: employee,
      attendances: attendances,
      payments: payments,
      advances: advances,
    );
  }

  // Dönemsel rapor (çalışan seçili) - ilerleme destekli
  Future<File> generatePeriodEmployeeReportWithProgress({
    required Employee employee,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Attendance> attendances,
    required List<Payment> payments,
    required List<Advance> advances,
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
      advances: advances,
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
    required List<List<Advance>> allAdvances,
    required List<Expense> expenses,
    String? outputDirectory,
    Uint8List? robotoFontBytes,
    Uint8List? robotoBoldFontBytes,
  }) async {
    return PdfPeriodGeneralService().generate(
      periodTitle: periodTitle,
      periodStart: periodStart,
      periodEnd: periodEnd,
      employees: employees,
      allAttendances: allAttendances,
      allPayments: allPayments,
      allAdvances: allAdvances,
      expenses: expenses,
      outputDirectory: outputDirectory,
      robotoFontBytes: robotoFontBytes,
      robotoBoldFontBytes: robotoBoldFontBytes,
    );
  }

  // Finansal özet raporu
  Future<File> generateFinancialSummaryReport({
    required String periodTitle,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Payment> allPayments,
    required List<Advance> allAdvances,
    required List<Expense> allExpenses,
    String? outputDirectory,
    Uint8List? robotoFontBytes,
    Uint8List? robotoBoldFontBytes,
  }) async {
    return PdfFinancialSummaryReportService().generate(
      periodTitle: periodTitle,
      periodStart: periodStart,
      periodEnd: periodEnd,
      allPayments: allPayments,
      allAdvances: allAdvances,
      allExpenses: allExpenses,
      outputDirectory: outputDirectory,
      robotoFontBytes: robotoFontBytes,
      robotoBoldFontBytes: robotoBoldFontBytes,
    );
  }

  Future<void> openPdf(File file) async {
    await OpenFile.open(file.path);
  }
}
