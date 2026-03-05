import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../../../../../models/employee.dart';
import '../../../../../../models/attendance.dart';
import '../../../../../../models/payment.dart';
import 'pdf_styles.dart';
import 'pdf_general_summary_helper.dart';
import '../pdf_report_utils.dart';

/// Genel rapor ana tablo oluşturma helper sınıfı
class PdfGeneralTableHelper {
  final PdfGeneralSummaryHelper _summaryHelper;
  final pw.Font _boldFont;

  PdfGeneralTableHelper(this._summaryHelper, this._boldFont);

  /// Ana özet tablosunu oluşturur (TOPLAM satırı hariç)
  pw.Widget buildSummaryTable({
    required List<Employee> employees,
    required List<List<Attendance>> allAttendances,
    required List<List<Payment>> allPayments,
    required List<List<dynamic>> allAdvances,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final tableData = _prepareTableData(
      employees: employees,
      allAttendances: allAttendances,
      allPayments: allPayments,
      allAdvances: allAdvances,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );

    // Header ve data satırlarını ayır
    final headers = tableData.first;
    final dataRows = tableData
        .skip(1)
        .take(tableData.length - 2)
        .toList(); // TOPLAM satırını çıkar

    return pw.Column(
      children: [
        // Ana tablo (TOPLAM hariç)
        pw.TableHelper.fromTextArray(
          data: dataRows,
          headers: headers,
          border: pw.TableBorder.all(color: PdfStyles.borderColor, width: 0.5),
          headerStyle: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            font: _boldFont,
            letterSpacing: 0.5,
          ),
          headerDecoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [PdfStyles.primaryColor, PdfColor.fromInt(0xFF5B21B6)],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
          ),
          headerAlignment: pw.Alignment.center,
          headerPadding: const pw.EdgeInsets.all(12),
          cellStyle: pw.TextStyle(fontSize: 10, color: PdfStyles.darkColor),
          cellAlignment: pw.Alignment.center,
          cellPadding: const pw.EdgeInsets.all(12),
          // Zebra striping - Tek satırlar açık gri
          oddRowDecoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF8FAFC),
          ),
          headerCount: 1,
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
          },
          cellAlignments: {
            0: pw.Alignment.center,
            1: pw.Alignment.center,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
          },
        ),
        // TOPLAM satırı - özel stil ile
        _buildTotalRow(tableData.last),
      ],
    );
  }

  /// TOPLAM satırını özel stil ile oluşturur
  pw.Widget _buildTotalRow(List<String> totalData) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFE5E7EB), // Koyu gri arka plan
        border: pw.Border.all(color: PdfStyles.borderColor, width: 0.5),
      ),
      child: pw.Row(
        children: [
          // Çalışan Adı Soyadı (TOPLAM)
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Center(
                child: pw.Text(
                  totalData[0],
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfStyles.darkColor,
                    font: _boldFont,
                  ),
                ),
              ),
            ),
          ),
          // Avans
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  left: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
                ),
              ),
              child: pw.Center(
                child: pw.Text(
                  totalData[1],
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfStyles.darkColor,
                    font: _boldFont,
                  ),
                ),
              ),
            ),
          ),
          // Yapılan Toplam Ödeme
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  left: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
                ),
              ),
              child: pw.Center(
                child: pw.Text(
                  totalData[2],
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfStyles.darkColor,
                    font: _boldFont,
                  ),
                ),
              ),
            ),
          ),
          // Toplam Ödenmeyen Gün Sayısı
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  left: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
                ),
              ),
              child: pw.Center(
                child: pw.Text(
                  totalData[3],
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfStyles.darkColor,
                    font: _boldFont,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tablo verilerini hazırlar
  List<List<String>> _prepareTableData({
    required List<Employee> employees,
    required List<List<Attendance>> allAttendances,
    required List<List<Payment>> allPayments,
    required List<List<dynamic>> allAdvances,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final tableData = <List<String>>[];

    // Header
    tableData.add([
      'Çalışan Adı Soyadı',
      'Avans',
      'Yapılan Toplam Ödeme',
      'Toplam Ödenmeyen Gün Sayısı',
    ]);

    double overallTotalPayment = 0;
    double overallTotalUnpaidDays = 0;
    double overallTotalAdvance = 0;

    // Her çalışan için satır ekle
    for (int i = 0; i < employees.length; i++) {
      final employee = employees[i];
      final attendances = allAttendances[i];
      final payments = allPayments[i];
      final advances = allAdvances[i];

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

      // Avans hesapla (dönem içi)
      final employeeTotalAdvance = advances.fold<double>(0, (sum, advance) {
        final advanceDate = advance.advanceDate as DateTime;
        if (!advanceDate.isBefore(periodStart) &&
            !advanceDate.isAfter(periodEnd)) {
          return sum + (advance.amount as double);
        }
        return sum;
      });
      overallTotalAdvance += employeeTotalAdvance;

      tableData.add([
        employee.name,
        PdfReportUtils.formatCurrency(employeeTotalAdvance),
        PdfReportUtils.formatCurrency(employeeTotalPayment),
        '${employeeTotalUnpaidDays.toStringAsFixed(1)} gün',
      ]);
    }

    // Toplam satırı - normal satır olarak ekle (özel çizgi yok)
    tableData.add([
      'TOPLAM',
      PdfReportUtils.formatCurrency(overallTotalAdvance),
      PdfReportUtils.formatCurrency(overallTotalPayment),
      '${overallTotalUnpaidDays.toStringAsFixed(1)} gün',
    ]);

    return tableData;
  }
}
