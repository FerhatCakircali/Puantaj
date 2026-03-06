import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../models/attendance.dart' as attendance;
import '../../../../../models/employee.dart';
import '../../../../../models/payment.dart';
import '../../../../../models/advance.dart';
import '../../../../../models/expense.dart';
import '../../widgets/screen_widgets/index.dart';
import '../../../../../services/attendance_service.dart';
import '../../../../../services/payment_service.dart';
import '../../../../../services/advance_service.dart';
import '../../../../../services/expense_service.dart';
import '../../../services/pdf_service.dart';
import '../../../services/pdf/pdf_base_service.dart';

/// PDF oluşturma işlemleri mixin'i
mixin ReportControllerPdfMixin<T extends StatefulWidget> on State<T> {
  final PdfService pdfService = PdfService();
  final AttendanceService attendanceService = AttendanceService();
  final PaymentService paymentService = PaymentService();
  final AdvanceService advanceService = AdvanceService();
  final ExpenseService expenseService = ExpenseService();

  List<Employee> get employees;
  bool get isLoading;
  ReportPeriod get selectedPeriodType;
  DateTime get customStartDate;
  DateTime get customEndDate;
  bool get isEmployeeSpecific;
  Employee? get selectedEmployee;
  ValueNotifier<double> get progressNotifier;

  set isLoading(bool value);

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

      progressNotifier.value = 0.1;

      final robotoFontBytes = (await rootBundle.load(
        'assets/fonts/Roboto-Regular.ttf',
      )).buffer.asUint8List();
      final robotoBoldFontBytes = (await rootBundle.load(
        'assets/fonts/Roboto-Bold.ttf',
      )).buffer.asUint8List();

      progressNotifier.value = 0.2;

      final file = isEmployeeSpecific
          ? await _generateEmployeeReport(periodTitle, outputDir)
          : await _generateGeneralReport(
              periodTitle,
              outputDir,
              robotoFontBytes,
              robotoBoldFontBytes,
            );

      progressNotifier.value = 0.95;

      // Genel rapor için dosyayı aç (isolate içinde açılamadığı için burada açıyoruz)
      if (!isEmployeeSpecific) {
        await PdfBaseService().openPdf(file);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Expanded(child: Text('Rapor oluşturuldu ve açıldı')),
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
        ),
      );

      debugPrint('ReportControllerMixin: Rapor oluşturuldu ve açıldı');
    } catch (e, stackTrace) {
      debugPrint('ReportControllerMixin: Rapor hatası: $e');
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
        // Progress'i 1.0'a ayarla, sonra kısa bir gecikmeyle sıfırla
        progressNotifier.value = 1.0;
        Future.delayed(const Duration(milliseconds: 500), () {
          progressNotifier.value = 0.0;
        });
      }
    }
  }

  Future<File> _generateEmployeeReport(
    String periodTitle,
    String outputDir,
  ) async {
    progressNotifier.value = 0.25;
    return await pdfService.generatePeriodEmployeeReportWithProgress(
      employee: selectedEmployee!,
      periodStart: customStartDate,
      periodEnd: customEndDate,
      attendances: await attendanceService.getAttendanceBetween(
        customStartDate,         customEndDate,
        workerId: selectedEmployee!.id,
      ),
      payments: await paymentService.getPaymentsByWorkerId(
        selectedEmployee!.id,
      ),
      advances: await advanceService.getWorkerAdvances(selectedEmployee!.id),
      periodTitle: periodTitle,
      progressCallback: (progress) {
        // Progress'i 0.25'ten 1.0'a ölçeklendir
        progressNotifier.value = 0.25 + (progress * 0.75);
      },
      outputDirectory: outputDir,
    );
  }

  Future<File> _generateGeneralReport(
    String periodTitle,
    String outputDir,
    Uint8List robotoFontBytes,
    Uint8List robotoBoldFontBytes,
  ) async {
    progressNotifier.value = 0.3;

    // Tüm masrafları bir kez çek (yöneticinin masrafları)
    final allExpensesData = (await expenseService.getExpensesByDateRange(
      customStartDate,
      customEndDate,
    )).map((e) => e.toMap()).toList();

    progressNotifier.value = 0.4;

    final allAttendancesData = await Future.wait(
      employees.map(
        (emp) async => (await attendanceService.getAttendanceBetween(
          customStartDate,
          customEndDate,
          workerId: emp.id,
        )).map((a) => a.toMap()).toList(),
      ),
    );

    progressNotifier.value = 0.5;

    final allPaymentsData = await Future.wait(
      employees.map(
        (emp) async => (await paymentService.getPaymentsByWorkerId(
          emp.id,
        )).map((p) => p.toMap()).toList(),
      ),
    );

    progressNotifier.value = 0.6;

    final allAdvancesData = await Future.wait(
      employees.map(
        (emp) async => (await advanceService.getWorkerAdvances(
          emp.id,
        )).map((a) => a.toMap()).toList(),
      ),
    );

    progressNotifier.value = 0.7;

    final filePath = await compute(_generatePeriodGeneralReportInIsolate, {
      'periodTitle': periodTitle,
      'periodStart': customStartDate.toIso8601String(),
      'periodEnd': customEndDate.toIso8601String(),
      'employees': employees.map((e) => e.toMap()).toList(),
      'allAttendances': allAttendancesData,
      'allPayments': allPaymentsData,
      'allAdvances': allAdvancesData,
      'expenses': allExpensesData,
      'outputDirectory': outputDir,
      'robotoFontBytes': robotoFontBytes,
      'robotoBoldFontBytes': robotoBoldFontBytes,
    });

    progressNotifier.value = 0.9;

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
    final allAdvances = (args['allAdvances'] as List)
        .map(
          (list) => (list as List)
              .map((a) => Advance.fromMap(Map<String, dynamic>.from(a)))
              .toList(),
        )
        .toList();
    final expenses = (args['expenses'] as List)
        .map((e) => Expense.fromMap(Map<String, dynamic>.from(e)))
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
      allAdvances: allAdvances,
      expenses: expenses,
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
    required AdvanceService advanceService,
    required ExpenseService expenseService,
    required String outputDir,
    required Uint8List robotoFontBytes,
    required Uint8List robotoBoldFontBytes,
  }) async {
    // Tüm masrafları bir kez çek (yöneticinin masrafları)
    final allExpensesData = (await expenseService.getExpensesByDateRange(
      customStartDate,
      customEndDate,
    )).map((e) => e.toMap()).toList();

    final filePath = await compute(_generatePeriodGeneralReportInIsolate, {
      'periodTitle': periodTitle,
      'periodStart': customStartDate.toIso8601String(),
      'periodEnd': customEndDate.toIso8601String(),
      'employees': employees.map((e) => e.toMap()).toList(),
      'allAttendances': await Future.wait(
        employees.map(
          (emp) async => (await attendanceService.getAttendanceBetween(
            customStartDate,             customEndDate,
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
      'allAdvances': await Future.wait(
        employees.map(
          (emp) async => (await advanceService.getWorkerAdvances(
            emp.id,
          )).map((a) => a.toMap()).toList(),
        ),
      ),
      'expenses': allExpensesData,
      'outputDirectory': outputDir,
      'robotoFontBytes': robotoFontBytes,
      'robotoBoldFontBytes': robotoBoldFontBytes,
    });

    return File(filePath);
  }

  /// Finansal özet raporu oluştur
  Future<void> createFinancialSummaryReport(BuildContext context) async {
    if (!mounted) return;

    debugPrint('ReportControllerMixin: Finansal özet raporu oluşturuluyor');

    setState(() => isLoading = true);
    progressNotifier.value = 0;

    try {
      String periodTitleText;
      switch (selectedPeriodType) {
        case ReportPeriod.daily:
          periodTitleText = 'Günlük Finansal Özet';
          break;
        case ReportPeriod.weekly:
          periodTitleText = 'Haftalık Finansal Özet';
          break;
        case ReportPeriod.monthly:
          periodTitleText = 'Aylık Finansal Özet';
          break;
        case ReportPeriod.yearly:
          periodTitleText = 'Yıllık Finansal Özet';
          break;
        case ReportPeriod.custom:
          periodTitleText = 'Özel Dönem Finansal Özet';
          break;
        case ReportPeriod.quarterly:
          periodTitleText = 'Üç Aylık Finansal Özet';
          break;
      }

      final outputDir = (await getTemporaryDirectory()).path;
      final robotoFontBytes = (await rootBundle.load(
        'assets/fonts/Roboto-Regular.ttf',
      )).buffer.asUint8List();
      final robotoBoldFontBytes = (await rootBundle.load(
        'assets/fonts/Roboto-Bold.ttf',
      )).buffer.asUint8List();

      progressNotifier.value = 0.3;

      debugPrint('Finansal Özet: Ödemeler çekiliyor...');
      debugPrint(
        '📊 Dönem: ${customStartDate.toIso8601String()} - ${customEndDate.toIso8601String()}',
      );

      // Tüm ödemeleri çek
      final allPayments = <Payment>[];
      for (var employee in employees) {
        final payments = await paymentService.getPaymentsByWorkerId(
          employee.id,
        );
        debugPrint('${employee.name}: ${payments.length} ödeme bulundu');
        allPayments.addAll(payments);
      }
      debugPrint('Toplam ${allPayments.length} ödeme bulundu');

      progressNotifier.value = 0.5;

      debugPrint('Finansal Özet: Avanslar çekiliyor...');

      // Tüm avansları çek
      final allAdvances = <Advance>[];
      for (var employee in employees) {
        final advances = await advanceService.getWorkerAdvances(employee.id);
        debugPrint('${employee.name}: ${advances.length} avans bulundu');
        allAdvances.addAll(advances);
      }
      debugPrint('Toplam ${allAdvances.length} avans bulundu');

      progressNotifier.value = 0.7;

      debugPrint('Finansal Özet: Masraflar çekiliyor...');

      // Tüm masrafları çek
      final allExpenses = await expenseService.getExpensesByDateRange(
        customStartDate,
        customEndDate,
      );
      debugPrint('Toplam ${allExpenses.length} masraf bulundu (dönem içi)');

      progressNotifier.value = 0.9;

      final file = await pdfService.generateFinancialSummaryReport(
        periodTitle: periodTitleText,
        periodStart: customStartDate,
        periodEnd: customEndDate,
        allPayments: allPayments,
        allAdvances: allAdvances,
        allExpenses: allExpenses,
        outputDirectory: outputDir,
        robotoFontBytes: robotoFontBytes,
        robotoBoldFontBytes: robotoBoldFontBytes,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Expanded(child: Text('Finansal özet raporu oluşturuldu')),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                tooltip: 'Paylaş',
                onPressed: () async {
                  await Share.shareXFiles([
                    XFile(file.path),
                  ], text: 'Finansal özet raporunu paylaşıyorum.');
                },
              ),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

      debugPrint(
        '✅ ReportControllerMixin: Finansal özet raporu oluşturuldu ve açıldı',
      );
    } catch (e, stackTrace) {
      debugPrint('ReportControllerMixin: Finansal özet raporu hatası: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Finansal özet raporu oluşturma hatası:\n${e.toString().split('.').first}',
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
        // Progress'i 1.0'a ayarla, sonra kısa bir gecikmeyle sıfırla
        progressNotifier.value = 1.0;
        Future.delayed(const Duration(milliseconds: 500), () {
          progressNotifier.value = 0.0;
        });
      }
    }
  }
}
