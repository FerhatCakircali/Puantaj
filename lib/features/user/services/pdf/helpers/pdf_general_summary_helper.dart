import 'package:pdf/widgets.dart' as pw;
import '../../../../../../models/employee.dart';
import '../../../../../../models/attendance.dart';
import '../../../../../../models/payment.dart';
import '../pdf_report_utils.dart';
import 'pdf_styles.dart';
import 'dart:math';

/// Genel rapor özet bilgileri için helper sınıfı
class PdfGeneralSummaryHelper {
  final PdfStyles _styles;

  PdfGeneralSummaryHelper(this._styles);

  /// Rapor başlığı ve tarih aralığı widget'ı oluşturur
  List<pw.Widget> buildHeader({
    required String periodTitle,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final dateFormat = PdfReportUtils.dateFormat;
    return [
      pw.Header(
        level: 1,
        child: pw.Text(
          'GENEL ÖZET - $periodTitle',
          style: _styles.sectionHeaderStyle,
        ),
      ),
      pw.SizedBox(height: 10),
      pw.Text(
        'Değerlendirme Tarihi Aralığı: ${dateFormat.format(periodStart)} - ${dateFormat.format(periodEnd)}',
        style: _styles.headerStyle,
      ),
      pw.SizedBox(height: 10),
    ];
  }

  /// Çalışan için toplam ödeme hesaplar
  double calculateEmployeeTotalPayment({
    required List<Payment> payments,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    return payments
        .where((payment) {
          final paymentDate = _normalizeDate(payment.paymentDate);
          final startDate = _normalizeDate(periodStart);
          final endDate = _normalizeDate(periodEnd);
          return !paymentDate.isBefore(startDate) &&
              !paymentDate.isAfter(endDate);
        })
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Çalışan için ödenen toplam gün sayısını hesaplar
  double calculateTotalPaidDays({
    required List<Payment> payments,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    return payments
        .where((payment) {
          final paymentDate = _normalizeDate(payment.paymentDate);
          final startDate = _normalizeDate(periodStart);
          final endDate = _normalizeDate(periodEnd);
          return !paymentDate.isBefore(startDate) &&
              !paymentDate.isAfter(endDate);
        })
        .fold(0.0, (sum, item) => sum + item.fullDays + (item.halfDays * 0.5));
  }

  /// Çalışan için toplam çalışılan gün sayısını hesaplar
  double calculateTotalWorkedDays({
    required List<Attendance> attendances,
    required Employee employee,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final filteredAttendances = attendances.where((a) {
      final attendanceDate = _normalizeDate(a.date);
      final startDate = _normalizeDate(periodStart);
      final endDate = _normalizeDate(periodEnd);
      final employeeStartDate = _normalizeDate(employee.startDate);
      return !attendanceDate.isBefore(startDate) &&
          !attendanceDate.isAfter(endDate) &&
          !attendanceDate.isBefore(employeeStartDate);
    }).toList();

    return filteredAttendances.fold(0.0, (sum, attendance) {
      if (attendance.status == AttendanceStatus.fullDay) {
        return sum + 1.0;
      } else if (attendance.status == AttendanceStatus.halfDay) {
        return sum + 0.5;
      }
      return sum;
    });
  }

  /// Çalışan için ödenmeyen gün sayısını hesaplar
  double calculateUnpaidDays({
    required double totalWorkedDays,
    required double totalPaidDays,
  }) {
    final unpaidDays = totalWorkedDays - totalPaidDays;
    return max(0.0, unpaidDays);
  }

  /// Tarihi normalize eder (saat bilgisini sıfırlar)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
