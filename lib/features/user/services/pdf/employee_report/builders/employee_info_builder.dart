import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../../../../../models/employee.dart';

/// Çalışan bilgileri PDF widget'ı oluşturucu
class EmployeeInfoBuilder {
  static pw.Widget build(Employee employee, pw.TextStyle headerStyle) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ÇALIŞAN BİLGİLERİ', style: headerStyle),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Ad Soyad:', style: headerStyle),
              pw.Text(employee.name),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Unvan:', style: headerStyle),
              pw.Text(employee.title),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Telefon:', style: headerStyle),
              pw.Text(employee.phone),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('İşe Başlama Tarihi:', style: headerStyle),
              pw.Text(dateFormat.format(employee.startDate)),
            ],
          ),
        ],
      ),
    );
  }
}
