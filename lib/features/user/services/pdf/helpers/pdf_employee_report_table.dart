import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:math';
import '../pdf_report_utils.dart';
import '../../../../../../models/attendance.dart';
import '../../../../../../models/payment.dart';
import '../../../../../../models/advance.dart';
import 'pdf_styles.dart';
import 'pdf_svg_icons.dart';

/// Çalışan raporu için tablo bileşenleri - Premium Bento Style
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
      padding: styles.cardPadding,
      decoration: styles.premiumCard(PdfStyles.successColor),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('DEVAM KAYITLARI ÖZETİ', style: styles.sectionHeaderStyle),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              PdfSvgIcons.buildIcon(
                PdfSvgIcons.calendar,
                size: styles.iconSize,
              ),
              pw.SizedBox(width: styles.iconSpacing),
              pw.Text(
                'Değerlendirme: ${dateFormat.format(periodStart)} - ${dateFormat.format(periodEnd)}',
                style: styles.labelStyle,
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.checkCircle,
                  'Tam Gün',
                  '$fullDayCount',
                  PdfStyles.successColor,
                  styles,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.halfCircle,
                  'Yarım Gün',
                  '$halfDayCount',
                  PdfStyles.warningColor,
                  styles,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.sum,
                  'Toplam',
                  totalDays.toStringAsFixed(1),
                  PdfStyles.primaryColor,
                  styles,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.xCircle,
                  'Devamsız',
                  '$absentCount',
                  PdfStyles.dangerColor,
                  styles,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatBox(
    String svgIcon,
    String label,
    String value,
    PdfColor color,
    PdfStyles styles,
  ) {
    return pw.Container(
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
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
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

    final totalPaidDays = periodPayments.fold<double>(
      0,
      (sum, payment) => sum + payment.fullDays + (payment.halfDays * 0.5),
    );

    final unpaidDays = max(0.0, totalWorkedDays - totalPaidDays);

    return pw.Container(
      padding: styles.cardPadding,
      decoration: styles.premiumCard(PdfStyles.warningColor),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ÖDEME BİLGİLERİ', style: styles.sectionHeaderStyle),
          pw.SizedBox(height: 16),

          // Stat boxes
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.money,
                  'Toplam Ödenen',
                  PdfReportUtils.formatCurrency(totalPaid),
                  PdfStyles.successColor,
                  styles,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.checkCircle,
                  'Ödenen Gün',
                  totalPaidDays.toStringAsFixed(1),
                  PdfStyles.primaryColor,
                  styles,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.xCircle,
                  'Ödenmeyen Gün',
                  unpaidDays.toStringAsFixed(1),
                  PdfStyles.dangerColor,
                  styles,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          periodPayments.isEmpty
              ? pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(color: PdfStyles.lightBg),
                  child: pw.Text(
                    'Henüz ödeme yapılmadı.',
                    style: styles.dataStyle,
                  ),
                )
              : _buildPaymentTable(periodPayments, styles),
        ],
      ),
    );
  }

  /// Ödeme tablosu oluştur
  static pw.Widget _buildPaymentTable(
    List<Payment> payments,
    PdfStyles styles,
  ) {
    return pw.Table.fromTextArray(
      headers: ['Tarih', 'Tam Gün', 'Yarım Gün', 'Ödeme'],
      data: payments.map((payment) {
        final dateFormat = PdfReportUtils.dateFormat;
        return [
          dateFormat.format(payment.paymentDate),
          '${payment.fullDays}',
          '${payment.halfDays}',
          PdfReportUtils.formatCurrency(payment.amount),
        ];
      }).toList(),
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
    );
  }

  /// Devam kayıtları tablosu oluştur
  static pw.Widget? buildAttendanceTable(
    List<Attendance> allDays,
    AttendanceStatus status,
    String title,
    PdfStyles styles,
  ) {
    final filteredDays = allDays.where((a) => a.status == status).toList();

    if (filteredDays.isEmpty) return null;

    final dateFormat = PdfReportUtils.dateFormat;

    // Renk seçimi
    PdfColor borderColor;
    if (status == AttendanceStatus.fullDay) {
      borderColor = PdfStyles.successColor;
    } else if (status == AttendanceStatus.halfDay) {
      borderColor = PdfStyles.warningColor;
    } else {
      borderColor = PdfStyles.dangerColor;
    }

    return pw.Container(
      padding: styles.cardPadding,
      decoration: styles.premiumCard(borderColor),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: styles.sectionHeaderStyle),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(color: PdfStyles.borderColor),
            children: [
              pw.TableRow(
                decoration: styles.tableHeaderDecoration,
                children: [_buildTableCell('Tarih', styles, isHeader: true)],
              ),
              ...filteredDays.asMap().entries.map((entry) {
                final index = entry.key;
                final attendance = entry.value;
                return pw.TableRow(
                  decoration: index % 2 == 0 ? styles.zebraStriping : null,
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
      child: pw.Center(
        child: pw.Text(
          text,
          style: isHeader ? styles.tableHeaderStyle : styles.dataStyle,
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  /// Avans bilgileri kartı oluştur
  static pw.Widget buildAdvanceInfo(
    List<Advance> advances,
    DateTime periodStart,
    DateTime periodEnd,
    PdfStyles styles,
  ) {
    final periodAdvances = _filterAdvancesByPeriod(
      advances,
      periodStart,
      periodEnd,
    );

    final totalAdvances = advances.fold<double>(
      0,
      (sum, advance) => sum + advance.amount,
    );

    final deductedAdvances = advances
        .where((a) => a.isDeducted)
        .fold<double>(0, (sum, advance) => sum + advance.amount);

    final pendingAdvances = advances
        .where((a) => !a.isDeducted)
        .fold<double>(0, (sum, advance) => sum + advance.amount);

    if (advances.isEmpty) {
      return pw.Container(
        padding: styles.cardPadding,
        decoration: styles.premiumCard(PdfStyles.successColor),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('AVANS BİLGİLERİ', style: styles.sectionHeaderStyle),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: PdfStyles.lightBg),
              child: pw.Text(
                'Avans kaydı bulunmamaktadır.',
                style: styles.dataStyle,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      padding: styles.cardPadding,
      decoration: styles.premiumCard(PdfStyles.warningColor),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('AVANS BİLGİLERİ', style: styles.sectionHeaderStyle),
          pw.SizedBox(height: 16),

          // Stat boxes
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.handMoney,
                  'Toplam Avans',
                  PdfReportUtils.formatCurrency(totalAdvances),
                  PdfStyles.warningColor,
                  styles,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.checkCircle,
                  'Düşülmüş',
                  PdfReportUtils.formatCurrency(deductedAdvances),
                  PdfStyles.successColor,
                  styles,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildStatBox(
                  PdfSvgIcons.xCircle,
                  'Bekleyen',
                  PdfReportUtils.formatCurrency(pendingAdvances),
                  PdfStyles.dangerColor,
                  styles,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          periodAdvances.isEmpty
              ? pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(color: PdfStyles.lightBg),
                  child: pw.Text(
                    'Bu dönemde avans kaydı bulunmamaktadır.',
                    style: styles.dataStyle,
                  ),
                )
              : _buildAdvanceTable(periodAdvances, styles),
        ],
      ),
    );
  }

  /// Avans tablosu oluştur
  static pw.Widget _buildAdvanceTable(
    List<Advance> advances,
    PdfStyles styles,
  ) {
    return pw.Table.fromTextArray(
      headers: ['Tarih', 'Tutar', 'Durum', 'Açıklama'],
      data: advances.map((advance) {
        final dateFormat = PdfReportUtils.dateFormat;
        return [
          dateFormat.format(advance.advanceDate),
          PdfReportUtils.formatCurrency(advance.amount),
          advance.isDeducted ? 'Düşüldü' : 'Bekliyor',
          advance.description ?? '-',
        ];
      }).toList(),
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

  /// Avansları döneme göre filtrele
  static List<Advance> _filterAdvancesByPeriod(
    List<Advance> advances,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    return advances.where((advance) {
      final advanceDate = DateTime(
        advance.advanceDate.year,
        advance.advanceDate.month,
        advance.advanceDate.day,
      );
      final startDate = DateTime(
        periodStart.year,
        periodStart.month,
        periodStart.day,
      );
      final endDate = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
      return !advanceDate.isBefore(startDate) && !advanceDate.isAfter(endDate);
    }).toList();
  }
}
