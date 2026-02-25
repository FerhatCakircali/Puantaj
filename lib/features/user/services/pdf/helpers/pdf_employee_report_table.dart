import 'package:pdf/widgets.dart' as pw;
import 'dart:math';
import '../pdf_report_utils.dart';
import '../../../../../../models/attendance.dart';
import '../../../../../../models/payment.dart';
import 'pdf_styles.dart';

/// Çalışan raporu için tablo bileşenleri
class PdfEmployeeReportTable {
  /// Devam kayıtları özeti kartı oluştur
  static pw.Widget buildAttendanceSummary(
    List<Attendance> allDays,
    DateTime periodStart,
    DateTime periodEnd,
    PdfStyles styles,
  ) {
    final dateFormat = PdfReportUtils.dateFormat;
    final fullDayCount = allDays
        .where((a) => a.status == AttendanceStatus.fullDay)
        .length;
    final halfDayCount = allDays
        .where((a) => a.status == AttendanceStatus.halfDay)
        .length;
    final totalDays = fullDayCount + (halfDayCount * 0.5);
    final absentCount = allDays
        .where((a) => a.status == AttendanceStatus.absent)
        .length;

    return pw.Container(
      padding: styles.standardPadding,
      decoration: styles.cardDecoration,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('DEVAM KAYITLARI ÖZETİ', style: styles.headerStyle),
          pw.Divider(),
          _buildInfoRow(
            'Değerlendirme Tarihi Aralığı:',
            '${dateFormat.format(periodStart)} - ${dateFormat.format(periodEnd)}',
            styles,
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow('Tam Gün Çalışma Sayısı:', '$fullDayCount gün', styles),
          pw.SizedBox(height: 5),
          _buildInfoRow(
            'Yarım Gün Çalışma Sayısı:',
            '$halfDayCount gün',
            styles,
          ),
          pw.SizedBox(height: 5),
          _buildInfoRow(
            'Geldiği Toplam Gün Sayısı:',
            '${totalDays.toStringAsFixed(1)} gün',
            styles,
          ),
          pw.SizedBox(height: 5),
          _buildInfoRow('Gelmediği Gün Sayısı:', '$absentCount gün', styles),
        ],
      ),
    );
  }

  /// Ödeme bilgileri kartı oluştur
  static pw.Widget buildPaymentInfo(
    List<Payment> payments,
    List<Attendance> allDays,
    DateTime periodStart,
    DateTime periodEnd,
    PdfStyles styles,
  ) {
    final periodPayments = _filterPaymentsByPeriod(
      payments,
      periodStart,
      periodEnd,
    );

    final totalPaid = periodPayments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );

    final totalWorkedDays =
        allDays.where((a) => a.status == AttendanceStatus.fullDay).length +
        (allDays.where((a) => a.status == AttendanceStatus.halfDay).length *
            0.5);

    final totalPaidDays = payments.fold<double>(
      0,
      (sum, payment) => sum + payment.fullDays + (payment.halfDays * 0.5),
    );

    final unpaidDays = max(0.0, totalWorkedDays - totalPaidDays);

    return pw.Container(
      padding: styles.standardPadding,
      decoration: styles.cardDecoration,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ÖDEME BİLGİLERİ', style: styles.headerStyle),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text('Ödemeler:', style: styles.headerStyle),
          pw.SizedBox(height: 5),
          periodPayments.isEmpty
              ? pw.Text('Henüz ödeme yapılmadı.')
              : _buildPaymentTable(periodPayments, styles),
          pw.SizedBox(height: 10),
          _buildInfoRow(
            'Toplam Ödenen:',
            '${totalPaid.toStringAsFixed(2)} ₺',
            styles,
          ),
          pw.SizedBox(height: 5),
          _buildInfoRow(
            'Ödenmeyen Gün Sayısı:',
            '${unpaidDays.toStringAsFixed(1)} gün',
            styles,
          ),
        ],
      ),
    );
  }

  /// Ödeme tablosu oluştur
  static pw.Widget _buildPaymentTable(
    List<Payment> payments,
    PdfStyles styles,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: styles.tableHeaderDecoration,
          children: [
            _buildTableCell('Tarih', styles, isHeader: true),
            _buildTableCell('Tam Gün', styles, isHeader: true),
            _buildTableCell('Yarım Gün', styles, isHeader: true),
            _buildTableCell('Ödeme', styles, isHeader: true),
          ],
        ),
        ...payments.map((payment) {
          final dateFormat = PdfReportUtils.dateFormat;
          return pw.TableRow(
            children: [
              _buildTableCell(dateFormat.format(payment.paymentDate), styles),
              _buildTableCell('${payment.fullDays}', styles),
              _buildTableCell('${payment.halfDays}', styles),
              _buildTableCell('${payment.amount.toStringAsFixed(2)} ₺', styles),
            ],
          );
        }),
      ],
    );
  }

  /// Devam kayıtları tablosu oluştur (tam gün, yarım gün, gelmedi)
  static pw.Widget? buildAttendanceTable(
    List<Attendance> allDays,
    AttendanceStatus status,
    String title,
    PdfStyles styles,
  ) {
    final filteredDays = allDays.where((a) => a.status == status).toList();

    if (filteredDays.isEmpty) return null;

    final dateFormat = PdfReportUtils.dateFormat;

    return pw.Container(
      padding: styles.standardPadding,
      decoration: styles.cardDecoration,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: styles.headerStyle),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                decoration: styles.tableHeaderDecoration,
                children: [_buildTableCell('Tarih', styles, isHeader: true)],
              ),
              ...filteredDays.map((attendance) {
                return pw.TableRow(
                  children: [
                    _buildTableCell(dateFormat.format(attendance.date), styles),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  /// Tablo hücresi oluştur
  static pw.Widget _buildTableCell(
    String text,
    PdfStyles styles, {
    bool isHeader = false,
  }) {
    return pw.Padding(
      padding: styles.cellPadding,
      child: pw.Text(text, style: isHeader ? styles.headerStyle : null),
    );
  }

  /// Bilgi satırı oluştur
  static pw.Widget _buildInfoRow(String label, String value, PdfStyles styles) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: styles.headerStyle),
        pw.Text(value),
      ],
    );
  }

  /// Ödemeleri döneme göre filtrele
  static List<Payment> _filterPaymentsByPeriod(
    List<Payment> payments,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    return payments.where((payment) {
      final paymentDate = DateTime(
        payment.paymentDate.year,
        payment.paymentDate.month,
        payment.paymentDate.day,
      );
      final startDate = DateTime(
        periodStart.year,
        periodStart.month,
        periodStart.day,
      );
      final endDate = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
      return !paymentDate.isBefore(startDate) && !paymentDate.isAfter(endDate);
    }).toList();
  }
}
