import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../../models/employee.dart';
import '../../widgets/screen_widgets/index.dart';
import '../../../services/pdf/pdf_base_service.dart';
import '../generators/employee_pdf_generator.dart';
import '../generators/period_pdf_generator.dart';
import '../generators/financial_pdf_generator.dart';

/// PDF oluşturma işlemleri mixin'i
///
/// Rapor ekranları için PDF oluşturma koordinatörü.
mixin ReportPdfMixin<T extends StatefulWidget> on State<T> {
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

    setState(() => isLoading = true);
    progressNotifier.value = 0;

    try {
      final periodTitle = _getPeriodTitle();
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

      if (!isEmployeeSpecific) {
        await PdfBaseService().openPdf(file);
      }

      if (!mounted) return;

      _showSuccessSnackBar(context, file, 'Rapor oluşturuldu ve açıldı');
    } catch (e, stackTrace) {
      debugPrint('Rapor hatası: $e\nStack trace: $stackTrace');
      if (!mounted) return;
      _showErrorSnackBar(context, e);
    } finally {
      _finalizeProgress();
    }
  }

  /// Finansal özet raporu oluştur
  Future<void> createFinancialSummaryReport(BuildContext context) async {
    if (!mounted) return;

    setState(() => isLoading = true);
    progressNotifier.value = 0;

    try {
      final periodTitle = _getFinancialPeriodTitle();
      final outputDir = (await getTemporaryDirectory()).path;
      final robotoFontBytes = (await rootBundle.load(
        'assets/fonts/Roboto-Regular.ttf',
      )).buffer.asUint8List();
      final robotoBoldFontBytes = (await rootBundle.load(
        'assets/fonts/Roboto-Bold.ttf',
      )).buffer.asUint8List();

      final generator = FinancialPdfGenerator();
      final file = await generator.generate(
        periodTitle: periodTitle,
        periodStart: customStartDate,
        periodEnd: customEndDate,
        employees: employees,
        outputDirectory: outputDir,
        robotoFontBytes: robotoFontBytes,
        robotoBoldFontBytes: robotoBoldFontBytes,
        progressNotifier: progressNotifier,
      );

      if (!mounted) return;

      _showSuccessSnackBar(context, file, 'Finansal özet raporu oluşturuldu');
    } catch (e, stackTrace) {
      debugPrint('Finansal özet raporu hatası: $e\nStack trace: $stackTrace');
      if (!mounted) return;
      _showErrorSnackBar(context, e);
    } finally {
      _finalizeProgress();
    }
  }

  Future<File> _generateEmployeeReport(
    String periodTitle,
    String outputDir,
  ) async {
    final generator = EmployeePdfGenerator();
    return await generator.generate(
      employee: selectedEmployee!,
      periodStart: customStartDate,
      periodEnd: customEndDate,
      periodTitle: periodTitle,
      outputDirectory: outputDir,
      progressNotifier: progressNotifier,
    );
  }

  Future<File> _generateGeneralReport(
    String periodTitle,
    String outputDir,
    Uint8List robotoFontBytes,
    Uint8List robotoBoldFontBytes,
  ) async {
    final generator = PeriodPdfGenerator();
    return await generator.generate(
      periodTitle: periodTitle,
      periodStart: customStartDate,
      periodEnd: customEndDate,
      employees: employees,
      outputDirectory: outputDir,
      robotoFontBytes: robotoFontBytes,
      robotoBoldFontBytes: robotoBoldFontBytes,
      progressNotifier: progressNotifier,
    );
  }

  String _getPeriodTitle() {
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

    return isEmployeeSpecific && selectedEmployee != null
        ? '${selectedEmployee!.name} - $periodTitleText'
        : periodTitleText;
  }

  String _getFinancialPeriodTitle() {
    switch (selectedPeriodType) {
      case ReportPeriod.daily:
        return 'Günlük Finansal Özet';
      case ReportPeriod.weekly:
        return 'Haftalık Finansal Özet';
      case ReportPeriod.monthly:
        return 'Aylık Finansal Özet';
      case ReportPeriod.yearly:
        return 'Yıllık Finansal Özet';
      case ReportPeriod.custom:
        return 'Özel Dönem Finansal Özet';
      case ReportPeriod.quarterly:
        return 'Üç Aylık Finansal Özet';
    }
  }

  void _showSuccessSnackBar(BuildContext context, File file, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Expanded(child: Text(message)),
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
  }

  void _showErrorSnackBar(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Rapor oluşturma hatası:\n${error.toString().split('.').first}',
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
  }

  void _finalizeProgress() {
    if (mounted) {
      setState(() => isLoading = false);
      progressNotifier.value = 1.0;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          progressNotifier.value = 0.0;
        }
      });
    }
  }
}
