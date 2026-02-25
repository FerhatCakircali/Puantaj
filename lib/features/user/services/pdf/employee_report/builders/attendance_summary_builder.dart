import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../../../../../models/employee.dart';
import '../../../../../../../models/attendance.dart';

/// Devam kayıtları özeti PDF widget'ı oluşturucu
class AttendanceSummaryBuilder {
  static pw.Widget build(
    Employee employee,
    List<Attendance> allDays,
    pw.TextStyle headerStyle,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final fullDaysCount = allDays
        .where((a) => a.status == AttendanceStatus.fullDay)
        .length;
    final halfDaysCount = allDays
        .where((a) => a.status == AttendanceStatus.halfDay)
        .length;
    final absentDaysCount = allDays
        .where((a) => a.status == AttendanceStatus.absent)
        .length;
    final totalWorkedDays = fullDaysCount + (halfDaysCount * 0.5);

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('DEVAM KAYITLARI ÖZETİ', style: headerStyle),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Değerlendirme Tarihi Aralığı:', style: headerStyle),
              pw.Text(
                '${dateFormat.format(employee.startDate)} - ${dateFormat.format(DateTime.now())}',
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Tam Gün Çalışma Sayısı:', style: headerStyle),
              pw.Text('$fullDaysCount gün'),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Yarım Gün Çalışma Sayısı:', style: headerStyle),
              pw.Text('$halfDaysCount gün'),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Geldiği Toplam Gün Sayısı:', style: headerStyle),
              pw.Text('${totalWorkedDays.toStringAsFixed(1)} gün'),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Gelmediği Gün Sayısı:', style: headerStyle),
              pw.Text('$absentDaysCount gün'),
            ],
          ),
        ],
      ),
    );
  }
}
