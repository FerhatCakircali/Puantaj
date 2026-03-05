import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../../../../../../models/attendance.dart';
import '../../helpers/pdf_styles.dart';
import '../../helpers/pdf_svg_icons.dart';
import '../../pdf_report_utils.dart';

/// Devam kayıtları detayları PDF widget'ı oluşturucu - Premium Bento Style
class AttendanceDetailsBuilder {
  static List<pw.Widget> build(List<Attendance> allDays, PdfStyles styles) {
    final widgets = <pw.Widget>[];

    // Tam gün kayıtları
    final fullDays = allDays
        .where((a) => a.status == AttendanceStatus.fullDay)
        .toList();
    if (fullDays.isNotEmpty) {
      widgets.add(
        _buildAttendanceCard(
          PdfSvgIcons.checkCircle,
          'TAM GÜN ÇALIŞMA KAYITLARI',
          fullDays,
          PdfStyles.successColor,
          styles,
        ),
      );
    }

    // Yarım gün kayıtları
    final halfDays = allDays
        .where((a) => a.status == AttendanceStatus.halfDay)
        .toList();
    if (halfDays.isNotEmpty) {
      if (widgets.isNotEmpty) widgets.add(pw.SizedBox(height: 16));
      widgets.add(
        _buildAttendanceCard(
          PdfSvgIcons.halfCircle,
          'YARIM GÜN ÇALIŞMA KAYITLARI',
          halfDays,
          PdfStyles.warningColor,
          styles,
        ),
      );
    }

    // Gelmediği günler
    final absentDays = allDays
        .where((a) => a.status == AttendanceStatus.absent)
        .toList();
    if (absentDays.isNotEmpty) {
      if (widgets.isNotEmpty) widgets.add(pw.SizedBox(height: 16));
      widgets.add(
        _buildAttendanceCard(
          PdfSvgIcons.xCircle,
          'GELMEDİĞİ GÜNLER',
          absentDays,
          PdfStyles.dangerColor,
          styles,
        ),
      );
    }

    return widgets;
  }

  /// Premium devam kartı oluştur
  static pw.Widget _buildAttendanceCard(
    String svgIcon,
    String title,
    List<Attendance> attendances,
    PdfColor color,
    PdfStyles styles,
  ) {
    return pw.Container(
      padding: styles.cardPadding,
      decoration: styles.premiumCard(color),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Başlık
          pw.Row(
            children: [
              PdfSvgIcons.buildIcon(svgIcon, size: styles.iconSize),
              pw.SizedBox(width: styles.iconSpacing),
              pw.Expanded(
                child: pw.Text(title, style: styles.sectionHeaderStyle),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(color: color),
                child: pw.Text(
                  '${attendances.length} gün',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Tarih tablosu (zebra striping)
          pw.Table(
            border: pw.TableBorder.all(color: PdfStyles.borderColor),
            columnWidths: {0: const pw.FlexColumnWidth(1)},
            children: [
              pw.TableRow(
                decoration: styles.tableHeaderDecoration,
                children: [
                  pw.Padding(
                    padding: styles.cellPadding,
                    child: pw.Center(
                      child: pw.Text('Tarih', style: styles.tableHeaderStyle),
                    ),
                  ),
                ],
              ),
              ...attendances.asMap().entries.map((entry) {
                final index = entry.key;
                final attendance = entry.value;
                final isEven = index % 2 == 0;

                return pw.TableRow(
                  decoration: isEven ? styles.zebraStriping : null,
                  children: [
                    pw.Padding(
                      padding: styles.cellPadding,
                      child: pw.Center(
                        child: pw.Text(
                          PdfReportUtils.dateFormat.format(attendance.date),
                          style: styles.dataStyle,
                        ),
                      ),
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
}
