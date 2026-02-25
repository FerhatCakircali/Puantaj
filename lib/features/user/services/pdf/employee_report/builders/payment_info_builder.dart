import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../../../../../../../models/attendance.dart';
import '../../../../../../../models/payment.dart';

/// Ödeme bilgileri PDF widget'ı oluşturucu
class PaymentInfoBuilder {
  static pw.Widget build(
    List<Attendance> allDays,
    List<Payment> payments,
    pw.TextStyle headerStyle,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final totalPaid = payments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    final totalWorkedDays =
        allDays.where((a) => a.status == AttendanceStatus.fullDay).length +
        (allDays.where((a) => a.status == AttendanceStatus.halfDay).length *
            0.5);
    final paidDays = payments.fold<double>(
      0,
      (sum, payment) => sum + payment.fullDays + (payment.halfDays * 0.5),
    );
    final unpaidDays = totalWorkedDays - paidDays;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ÖDEME BİLGİLERİ', style: headerStyle),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text('Ödemeler:', style: headerStyle),
          pw.SizedBox(height: 5),
          payments.isEmpty
              ? pw.Text('Henüz ödeme yapılmadı.')
              : pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Tarih', style: headerStyle),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Tam Gün', style: headerStyle),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Yarım Gün', style: headerStyle),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Ödeme', style: headerStyle),
                        ),
                      ],
                    ),
                    ...payments.map((payment) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              dateFormat.format(payment.paymentDate),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('${payment.fullDays}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('${payment.halfDays}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              '${payment.amount.toStringAsFixed(2)} ₺',
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Toplam Ödenen:', style: headerStyle),
              pw.Text('${totalPaid.toStringAsFixed(2)} ₺'),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Ödenmeyen Gün Sayısı:', style: headerStyle),
              pw.Text('${unpaidDays.toStringAsFixed(1)} gün'),
            ],
          ),
        ],
      ),
    );
  }
}
