import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../../../../../../models/attendance.dart';
import '../../../../../../../models/payment.dart';
import '../../helpers/pdf_styles.dart';
import '../../helpers/pdf_svg_icons.dart';
import '../../pdf_report_utils.dart';

/// Ödeme bilgileri PDF widget'ı oluşturucu - Premium Bento Style
class PaymentInfoBuilder {
  static pw.Widget build(
    List<Attendance> allDays,
    List<Payment> payments,
    PdfStyles styles,
    pw.Font? boldFont,
  ) {
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
    final displayUnpaidDays = unpaidDays < 0 ? 0.0 : unpaidDays;

    return pw.Container(
      padding: styles.cardPadding,
      decoration: styles.premiumCard(PdfStyles.warningColor),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ÖDEME BİLGİLERİ', style: styles.sectionHeaderStyle),
          pw.SizedBox(height: 16),

          // İstatistik kartları
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                PdfSvgIcons.money,
                'Toplam Ödenen',
                PdfReportUtils.formatCurrency(totalPaid),
                PdfStyles.successColor,
                styles,
              ),
              pw.SizedBox(width: 12),
              _buildStatCard(
                PdfSvgIcons.checkCircle,
                'Ödenen Gün',
                paidDays.toStringAsFixed(1),
                PdfStyles.primaryColor,
                styles,
              ),
              pw.SizedBox(width: 12),
              _buildStatCard(
                PdfSvgIcons.xCircle,
                'Ödenmeyen Gün',
                displayUnpaidDays.toStringAsFixed(1),
                PdfStyles.dangerColor,
                styles,
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Ödeme tablosu
          if (payments.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: PdfStyles.lightBg),
              child: pw.Text('Henüz ödeme yapılmadı.', style: styles.dataStyle),
            )
          else
            pw.Table.fromTextArray(
              headers: ['Tarih', 'Tam Gün', 'Yarım Gün', 'Ödeme'],
              data: payments
                  .map(
                    (payment) => [
                      PdfReportUtils.dateFormat.format(payment.paymentDate),
                      '${payment.fullDays}',
                      '${payment.halfDays}',
                      PdfReportUtils.formatCurrency(payment.amount),
                    ],
                  )
                  .toList(),
              border: pw.TableBorder.all(color: PdfStyles.borderColor),
              headerStyle: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                font: styles.base.boldFont,
              ),
              headerDecoration: styles.tableHeaderDecoration,
              headerAlignment: pw.Alignment.center,
              headerPadding: styles.cellPadding,
              cellStyle: styles.dataStyle,
              cellAlignment: pw.Alignment.center,
              cellPadding: styles.cellPadding,
              oddRowDecoration: styles.zebraStriping,
              headerCount: 1,
            ),
        ],
      ),
    );
  }

  /// Stat card oluştur
  static pw.Widget _buildStatCard(
    String svgIcon,
    String label,
    String value,
    PdfColor color,
    PdfStyles styles,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: styles.statBox(color),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PdfSvgIcons.buildIcon(svgIcon, size: styles.iconSize),
            pw.SizedBox(height: 8),
            pw.Text(label, style: styles.labelStyle),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
