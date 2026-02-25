import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../models/attendance.dart' as attendance;
import '../../../../../models/employee.dart';
import '../../../../../models/payment.dart';
import '../../widgets/screen_widgets/index.dart';
import '../../../../../services/attendance_service.dart';
import '../../../../../services/payment_service.dart';
import '../../../services/pdf_service.dart';

/// PDF oluşturma işlemleri mixin'i
mixin ReportControllerPdfMixin<T extends StatefulWidget> on State<T> {
  final PdfService pdfService = PdfService();
  final AttendanceService attendanceService = AttendanceService();
  final PaymentService paymentService = PaymentService();

  List<Employee> get employees;
  bool get isLoading;
  ReportPeriod get selectedPeriodType;
  DateTime get customStartDate;
  DateTime get customEndDate;
  bool get isEmployeeSpecific;
  Employee? get selectedEmployee;
  ValueNotifier<double> get progressNotifier;

  set isLoading(bool value);

  Future<void> showReportNotification(File file, String title);

  /// Dönemsel rapor oluştur
  Future<void> createPeriodReport(BuildContext context) async {
    if (!mounted) return;

    debugPrint('📄 ReportControllerMixin: Dönemsel rapor oluşturuluyor');

    setState(() => isLoading = true);
    progressNotifier.value = 0;

    try {
      String periodTitleText;
      switch (selectedPeriodType) {
        case ReportPeriod.daily:
          periodTitleText = 'Günlük Rapor';
          break;
        case ReportPeriod.weekly:
          periodTitleText = 'Haftalık Rapor';
          break;
        case ReportPeriod.monthly:
          periodTitleText = 'Aylık Rapor';
          break;
        case ReportPeriod.yearly:
          periodTitleText = 'Yıllık Rapor';
          break;
        case ReportPeriod.custom:
          periodTitleText = 'Özel Dönem Raporu';
          break;
        case ReportPeriod.quarterly:
          periodTitleText = 'Üç Aylık Rapor';
          break;
      }

      final periodTitle = isEmployeeSpecific && selectedEmployee != null
          ? '${selectedEmployee!.name} - $periodTitleText'
          : periodTitleText;

      final outputDir = (await getTemporaryDirectory()).path;
      final robotoFontBytes = (await rootBundle.load(
        'assets/fonts/Roboto-Regular.ttf',
      )).buffer.asUint8List();
      final robotoBoldFontBytes = (await rootBundle.load(
        'assets/fonts/Roboto-Bold.ttf',
      )).buffer.asUint8List();

      final file = isEmployeeSpecific
          ? await _generateEmployeeReport(periodTitle, outputDir)
          : await _generateGeneralReport(
              periodTitle,
              outputDir,
              robotoFontBytes,
              robotoBoldFontBytes,
            );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Expanded(child: Text('Rapor oluşturuldu')),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                tooltip: 'Paylaş',
                onPressed: () async {
                  await Share.shareXFiles([
                    XFile(file.path),
                  ], text: 'PDF raporunu paylaşıyorum.');
                },
              ),
            ],
          ),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'AÇ',
            onPressed: () => pdfService.openPdf(file),
          ),
        ),
      );

      await showReportNotification(file, 'Dönemsel Rapor');

      debugPrint('✅ ReportControllerMixin: Rapor oluşturuldu');
    } catch (e, stackTrace) {
      debugPrint('❌ ReportControllerMixin: Rapor hatası: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rapor oluşturma hatası:\n${e.toString().split('.').first}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'TAMAM',
            onPressed: () {},
            textColor: Colors.white,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        progressNotifier.value = 1.0;
      }
    }
  }

  Future<File> _generateEmployeeReport(
    String periodTitle,
    String outputDir,
  ) async {
    progressNotifier.value = 0;
    return await pdfService.generatePeriodEmployeeReportWithProgress(
      employee: selectedEmployee!,
      periodStart: customStartDate,
      periodEnd: customEndDate,
      attendances: await attendanceService.getAttendanceBetween(
        selectedEmployee!.startDate,
        customEndDate,
        workerId: selectedEmployee!.id,
      ),
      payments: await paymentService.getPaymentsByWorkerId(
        selectedEmployee!.id,
      ),
      periodTitle: periodTitle,
      progressCallback: (progress) => progressNotifier.value = progress,
      outputDirectory: outputDir,
    );
  }

  Future<File> _generateGeneralReport(
    String periodTitle,
    String outputDir,
    Uint8List robotoFontBytes,
    Uint8List robotoBoldFontBytes,
  ) async {
    final filePath = await compute(_generatePeriodGeneralReportInIsolate, {
      'periodTitle': periodTitle,
      'periodStart': customStartDate.toIso8601String(),
      'periodEnd': customEndDate.toIso8601String(),
      'employees': employees.map((e) => e.toMap()).toList(),
      'allAttendances': await Future.wait(
        employees.map(
          (emp) async => (await attendanceService.getAttendanceBetween(
            emp.startDate,
            customEndDate,
            workerId: emp.id,
          )).map((a) => a.toMap()).toList(),
        ),
      ),
      'allPayments': await Future.wait(
        employees.map(
          (emp) async => (await paymentService.getPaymentsByWorkerId(
            emp.id,
          )).map((p) => p.toMap()).toList(),
        ),
      ),
      'outputDirectory': outputDir,
      'robotoFontBytes': robotoFontBytes,
      'robotoBoldFontBytes': robotoBoldFontBytes,
    });

    return File(filePath);
  }

  static Future<String> _generatePeriodGeneralReportInIsolate(
    Map<String, dynamic> args,
  ) async {
    final periodTitle = args['periodTitle'] as String;
    final periodStart = DateTime.parse(args['periodStart'] as String);
    final periodEnd = DateTime.parse(args['periodEnd'] as String);
    final employees = (args['employees'] as List)
        .map((e) => Employee.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final allAttendances = (args['allAttendances'] as List)
        .map(
          (list) => (list as List)
              .map(
                (a) =>
                    attendance.Attendance.fromMap(Map<String, dynamic>.from(a)),
              )
              .toList(),
        )
        .toList();
    final allPayments = (args['allPayments'] as List)
        .map(
          (list) => (list as List)
              .map((p) => Payment.fromMap(Map<String, dynamic>.from(p)))
              .toList(),
        )
        .toList();
    final outputDirectory = args['outputDirectory'] as String?;
    final robotoFontBytes = args['robotoFontBytes'] as Uint8List;
    final robotoBoldFontBytes = args['robotoBoldFontBytes'] as Uint8List;

    final file = await PdfService().generatePeriodGeneralReport(
      periodTitle: periodTitle,
      periodStart: periodStart,
      periodEnd: periodEnd,
      employees: employees,
      allAttendances: allAttendances,
      allPayments: allPayments,
      outputDirectory: outputDirectory,
      robotoFontBytes: robotoFontBytes,
      robotoBoldFontBytes: robotoBoldFontBytes,
    );

    return file.path;
  }

  /// Genel rapor oluştur (static metod - ana mixin'den çağrılır)
  static Future<File> generateGeneralReport({
    required String periodTitle,
    required DateTime customStartDate,
    required DateTime customEndDate,
    required List<Employee> employees,
    required AttendanceService attendanceService,
    required PaymentService paymentService,
    required String outputDir,
    required Uint8List robotoFontBytes,
    required Uint8List robotoBoldFontBytes,
  }) async {
    final filePath = await compute(_generatePeriodGeneralReportInIsolate, {
      'periodTitle': periodTitle,
      'periodStart': customStartDate.toIso8601String(),
      'periodEnd': customEndDate.toIso8601String(),
      'employees': employees.map((e) => e.toMap()).toList(),
      'allAttendances': await Future.wait(
        employees.map(
          (emp) async => (await attendanceService.getAttendanceBetween(
            emp.startDate,
            customEndDate,
            workerId: emp.id,
          )).map((a) => a.toMap()).toList(),
        ),
      ),
      'allPayments': await Future.wait(
        employees.map(
          (emp) async => (await paymentService.getPaymentsByWorkerId(
            emp.id,
          )).map((p) => p.toMap()).toList(),
        ),
      ),
      'outputDirectory': outputDir,
      'robotoFontBytes': robotoFontBytes,
      'robotoBoldFontBytes': robotoBoldFontBytes,
    });

    return File(filePath);
  }
}
