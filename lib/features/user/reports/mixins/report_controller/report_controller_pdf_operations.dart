import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../models/employee.dart';
import '../../widgets/screen_widgets/index.dart';
import '../../../../../services/attendance_service.dart';
import '../../../../../services/payment_service.dart';
import '../../../../../services/advance_service.dart';
import '../../../../../services/expense_service.dart';
import '../../../services/pdf_service.dart';
import 'report_controller_pdf_mixin.dart';

/// PDF oluşturma operasyonları
class ReportControllerPdfOperations {
  /// Dönemsel rapor oluştur
  static Future<void> createPeriodReport({
    required BuildContext context,
    required State state,
    required ReportPeriod selectedPeriodType,
    required bool isEmployeeSpecific,
    required Employee? selectedEmployee,
    required DateTime customStartDate,
    required DateTime customEndDate,
    required List<Employee> employees,
    required AttendanceService attendanceService,
    required PaymentService paymentService,
    required AdvanceService advanceService,
    required ExpenseService expenseService,
    required PdfService pdfService,
    required ValueNotifier<double> progressNotifier,
    required void Function(bool) onLoadingUpdate,
  }) async {
    if (!state.mounted) return;

    debugPrint('📄 ReportControllerMixin: Dönemsel rapor oluşturuluyor');

    onLoadingUpdate(true);
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
          ? '${selectedEmployee.name} - $periodTitleText'
          : periodTitleText;

      final outputDir = (await getTemporaryDirectory()).path;
      final robotoFontBytes = (await rootBundle.load(
        'assets/fonts/Roboto-Regular.ttf',
      )).buffer.asUint8List();
      final robotoBoldFontBytes = (await rootBundle.load(
        'assets/fonts/Roboto-Bold.ttf',
      )).buffer.asUint8List();

      final file = isEmployeeSpecific
          ? await _generateEmployeeReport(
              periodTitle: periodTitle,
              outputDir: outputDir,
              selectedEmployee: selectedEmployee!,
              customStartDate: customStartDate,
              customEndDate: customEndDate,
              attendanceService: attendanceService,
              paymentService: paymentService,
              advanceService: advanceService,
              pdfService: pdfService,
              progressNotifier: progressNotifier,
            )
          : await ReportControllerPdfMixin.generateGeneralReport(
              periodTitle: periodTitle,
              customStartDate: customStartDate,
              customEndDate: customEndDate,
              employees: employees,
              attendanceService: attendanceService,
              paymentService: paymentService,
              advanceService: advanceService,
              expenseService: expenseService,
              outputDir: outputDir,
              robotoFontBytes: robotoFontBytes,
              robotoBoldFontBytes: robotoBoldFontBytes,
            );

      if (!state.mounted) return;

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

      debugPrint('✅ ReportControllerMixin: Rapor oluşturuldu ve açıldı');
    } catch (e, stackTrace) {
      debugPrint('❌ ReportControllerMixin: Rapor hatası: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!state.mounted) return;

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
      if (state.mounted) {
        onLoadingUpdate(false);
        progressNotifier.value = 1.0;
      }
    }
  }

  static Future<File> _generateEmployeeReport({
    required String periodTitle,
    required String outputDir,
    required Employee selectedEmployee,
    required DateTime customStartDate,
    required DateTime customEndDate,
    required AttendanceService attendanceService,
    required PaymentService paymentService,
    required AdvanceService advanceService,
    required PdfService pdfService,
    required ValueNotifier<double> progressNotifier,
  }) async {
    progressNotifier.value = 0;
    return await pdfService.generatePeriodEmployeeReportWithProgress(
      employee: selectedEmployee,
      periodStart: customStartDate,
      periodEnd: customEndDate,
      attendances: await attendanceService.getAttendanceBetween(
        selectedEmployee.startDate,
        customEndDate,
        workerId: selectedEmployee.id,
      ),
      payments: await paymentService.getPaymentsByWorkerId(selectedEmployee.id),
      advances: await advanceService.getWorkerAdvances(selectedEmployee.id),
      periodTitle: periodTitle,
      progressCallback: (progress) => progressNotifier.value = progress,
      outputDirectory: outputDir,
    );
  }
}
