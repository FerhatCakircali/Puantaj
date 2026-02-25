import 'package:pdf/widgets.dart' as pw;
import '../../../../../../models/employee.dart';
import '../../../../../../models/attendance.dart';
import '../../../../../../models/payment.dart';
import '../pdf_report_utils.dart';
import 'pdf_styles.dart';
import 'dart:math';

/// Genel rapor çalışan detay kartları için helper sınıfı
class PdfGeneralDetailHelper {
  final PdfStyles _styles;

  PdfGeneralDetailHelper(this._styles);

  /// Çalışan bilgileri kartı oluşturur
  pw.Widget buildEmployeeInfoCard(Employee employee) {
    final dateFormat = PdfReportUtils.dateFormat;
    return pw.Container(
      padding: _styles.standardPadding,
      decoration: _styles.cardDecoration,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ÇALIŞAN BİLGİLERİ', style: _styles.headerStyle),
          pw.Divider(),
          _buildInfoRow('Ad Soyad:', employee.name),
          pw.SizedBox(height: 5),
          _buildInfoRow('Unvan:', employee.title),
          pw.SizedBox(height: 5),
          _buildInfoRow('Telefon:', employee.phone),
          pw.SizedBox(height: 5),
          _buildInfoRow(
            'İşe Başlama Tarihi:',
            dateFormat.format(employee.startDate),
          ),
        ],
      ),
    );
  }

  /// Devam kayıtları özet kartı oluşturur
  pw.Widget buildAttendanceSummaryCard({
    required List<Attendance> allDays,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final dateFormat = PdfReportUtils.dateFormat;
    final fullDayCount = allDays
        .where((a) => a.status == AttendanceStatus.fullDay)
        .length;
    final halfDayCount = allDays
        .where((a) => a.status == AttendanceStatus.halfDay)
        .length;
    final absentCount = allDays
        .where((a) => a.status == AttendanceStatus.absent)
        .length;
    final totalDays = fullDayCount + (halfDayCount * 0.5);

    return pw.Container(
      padding: _styles.standardPadding,
      decoration: _styles.cardDecoration,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('DEVAM KAYITLARI ÖZETİ', style: _styles.headerStyle),
          pw.Divider(),
          _buildInfoRow(
            'Değerlendirme Tarihi Aralığı:',
            '${dateFormat.format(periodStart)} - ${dateFormat.format(periodEnd)}',
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow('Tam Gün Çalışma Sayısı:', '$fullDayCount gün'),
          pw.SizedBox(height: 5),
          _buildInfoRow('Yarım Gün Çalışma Sayısı:', '$halfDayCount gün'),
          pw.SizedBox(height: 5),
          _buildInfoRow(
            'Geldiği Toplam Gün Sayısı:',
            '${totalDays.toStringAsFixed(1)} gün',
          ),
          pw.SizedBox(height: 5),
          _buildInfoRow('Gelmediği Gün Sayısı:', '$absentCount gün'),
        ],
      ),
    );
  }

  /// Ödeme bilgileri kartı oluşturur
  pw.Widget buildPaymentInfoCard({
    required List<Payment> payments,
    required List<Attendance> allDays,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final dateFormat = PdfReportUtils.dateFormat;
    final filteredPayments = _filterPaymentsByPeriod(
      payments,
      periodStart,
      periodEnd,
    );

    final totalPaid = filteredPayments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );

    final totalPaidDays = payments.fold<double>(
      0,
      (sum, payment) => sum + payment.fullDays + (payment.halfDays * 0.5),
    );

    final totalWorkedDays =
        allDays.where((a) => a.status == AttendanceStatus.fullDay).length +
        (allDays.where((a) => a.status == AttendanceStatus.halfDay).length *
            0.5);

    final unpaidDays = max(0.0, totalWorkedDays - totalPaidDays);

    return pw.Container(
      padding: _styles.standardPadding,
      decoration: _styles.cardDecoration,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ÖDEME BİLGİLERİ', style: _styles.headerStyle),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text('Ödemeler:', style: _styles.headerStyle),
          pw.SizedBox(height: 5),
          filteredPayments.isEmpty
              ? pw.Text('Henüz ödeme yapılmadı.')
              : _buildPaymentTable(filteredPayments, dateFormat),
          pw.SizedBox(height: 10),
          _buildInfoRow('Toplam Ödenen:', '${totalPaid.toStringAsFixed(2)} ₺'),
          pw.SizedBox(height: 5),
          _buildInfoRow(
            'Ödenmeyen Gün Sayısı:',
            '${unpaidDays.toStringAsFixed(1)} gün',
          ),
        ],
      ),
    );
  }

  /// Devam kayıtları detay tablosu oluşturur
  pw.Widget buildAttendanceDetailTable({
    required String title,
    required List<Attendance> attendances,
  }) {
    final dateFormat = PdfReportUtils.dateFormat;
    return pw.Container(
      padding: _styles.standardPadding,
      decoration: _styles.cardDecoration,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: _styles.headerStyle),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                decoration: _styles.tableHeaderDecoration,
                children: [
                  pw.Padding(
                    padding: _styles.cellPadding,
                    child: pw.Text('Tarih', style: _styles.headerStyle),
                  ),
                ],
              ),
              ...attendances.map((attendance) {
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: _styles.cellPadding,
                      child: pw.Text(dateFormat.format(attendance.date)),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  /// Rapor footer'ı oluşturur
  pw.Widget buildReportFooter(String employeeName) {
    final dateFormat = PdfReportUtils.dateFormat;
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Bu rapor $employeeName için oluşturulmuştur.'),
              pw.Text('Oluşturma Tarihi: ${dateFormat.format(DateTime.now())}'),
            ],
          ),
        ],
      ),
    );
  }

  /// Bilgi satırı oluşturur
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: _styles.headerStyle),
        pw.Text(value),
      ],
    );
  }

  /// Ödeme tablosu oluşturur
  pw.Widget _buildPaymentTable(List<Payment> payments, dynamic dateFormat) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: _styles.tableHeaderDecoration,
          children: [
            pw.Padding(
              padding: _styles.cellPadding,
              child: pw.Text('Tarih', style: _styles.headerStyle),
            ),
            pw.Padding(
              padding: _styles.cellPadding,
              child: pw.Text('Tam Gün', style: _styles.headerStyle),
            ),
            pw.Padding(
              padding: _styles.cellPadding,
              child: pw.Text('Yarım Gün', style: _styles.headerStyle),
            ),
            pw.Padding(
              padding: _styles.cellPadding,
              child: pw.Text('Ödeme', style: _styles.headerStyle),
            ),
          ],
        ),
        ...payments.map((payment) {
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: _styles.cellPadding,
                child: pw.Text(dateFormat.format(payment.paymentDate)),
              ),
              pw.Padding(
                padding: _styles.cellPadding,
                child: pw.Text('${payment.fullDays}'),
              ),
              pw.Padding(
                padding: _styles.cellPadding,
                child: pw.Text('${payment.halfDays}'),
              ),
              pw.Padding(
                padding: _styles.cellPadding,
                child: pw.Text('${payment.amount.toStringAsFixed(2)} ₺'),
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Ödemeleri periyoda göre filtreler
  List<Payment> _filterPaymentsByPeriod(
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
