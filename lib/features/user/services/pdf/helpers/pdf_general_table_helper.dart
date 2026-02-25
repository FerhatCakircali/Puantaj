import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../../../../../models/employee.dart';
import '../../../../../../models/attendance.dart';
import '../../../../../../models/payment.dart';
import 'pdf_styles.dart';
import 'pdf_general_summary_helper.dart';
import 'package:pdf/src/widgets/table_helper.dart';

/// Genel rapor ana tablo oluşturma helper sınıfı
class PdfGeneralTableHelper {
  final PdfStyles _styles;
  final PdfGeneralSummaryHelper _summaryHelper;

  PdfGeneralTableHelper(this._styles, this._summaryHelper);

  /// Ana özet tablosunu oluşturur
  pw.Widget buildSummaryTable({
    required List<Employee> employees,
    required List<List<Attendance>> allAttendances,
    required List<List<Payment>> allPayments,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final tableData = _prepareTableData(
      employees: employees,
      allAttendances: allAttendances,
      allPayments: allPayments,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );

    return TableHelper.fromTextArray(
      headers: tableData.first,
      data: tableData.skip(1).toList(),
      border: pw.TableBorder.all(),
      headerStyle: _styles.headerStyle.copyWith(color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellPadding: _styles.cellPadding,
      cellAlignment: pw.Alignment.centerLeft,
      cellStyle: _styles.dataStyle,
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
    );
  }

  /// Tablo verilerini hazırlar
  List<List<String>> _prepareTableData({
    required List<Employee> employees,
    required List<List<Attendance>> allAttendances,
    required List<List<Payment>> allPayments,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final tableData = <List<String>>[];

    // Header
    tableData.add([
      'Çalışan Adı Soyadı',
      'Unvanı',
      'Yapılan Toplam Ödeme',
      'Toplam Ödenmeyen Gün Sayısı',
    ]);

    double overallTotalPayment = 0;
    double overallTotalUnpaidDays = 0;

    // Her çalışan için satır ekle
    for (int i = 0; i < employees.length; i++) {
      final employee = employees[i];
      final attendances = allAttendances[i];
      final payments = allPayments[i];

      final employeeTotalPayment = _summaryHelper.calculateEmployeeTotalPayment(
        payments: payments,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      overallTotalPayment += employeeTotalPayment;

      final totalPaidDays = _summaryHelper.calculateTotalPaidDays(
        payments: payments,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      final totalWorkedDays = _summaryHelper.calculateTotalWorkedDays(
        attendances: attendances,
        employee: employee,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      final employeeTotalUnpaidDays = _summaryHelper.calculateUnpaidDays(
        totalWorkedDays: totalWorkedDays,
        totalPaidDays: totalPaidDays,
      );
      overallTotalUnpaidDays += employeeTotalUnpaidDays;

      tableData.add([
        employee.name,
        employee.title,
        '${employeeTotalPayment.toStringAsFixed(2)} TL',
        '${employeeTotalUnpaidDays.toStringAsFixed(1)} gün',
      ]);
    }

    // Toplam satırı
    tableData.add([
      'TOPLAM',
      '',
      '${overallTotalPayment.toStringAsFixed(2)} TL',
      '${overallTotalUnpaidDays.toStringAsFixed(1)} gün',
    ]);

    return tableData;
  }
}
