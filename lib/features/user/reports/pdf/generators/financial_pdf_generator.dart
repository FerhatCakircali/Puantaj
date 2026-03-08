import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../../models/employee.dart';
import '../../../../../models/payment.dart';
import '../../../../../models/advance.dart';
import '../../../services/pdf_service.dart';
import '../helpers/pdf_data_loader.dart';

/// Finansal özet raporu PDF oluşturucu
///
/// Tüm ödemeler, avanslar ve masrafları içeren finansal özet raporu oluşturur.
class FinancialPdfGenerator {
  final PdfService _pdfService;
  final PdfDataLoader _dataLoader;

  FinancialPdfGenerator({PdfService? pdfService, PdfDataLoader? dataLoader})
    : _pdfService = pdfService ?? PdfService(),
      _dataLoader = dataLoader ?? PdfDataLoader();

  /// Finansal özet raporu oluştur
  Future<File> generate({
    required String periodTitle,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Employee> employees,
    required String outputDirectory,
    required Uint8List robotoFontBytes,
    required Uint8List robotoBoldFontBytes,
    required ValueNotifier<double> progressNotifier,
  }) async {
    progressNotifier.value = 0.3;

    final allPayments = <Payment>[];
    for (var employee in employees) {
      final payments = await _dataLoader.loadEmployeePayments(employee.id);
      allPayments.addAll(payments);
    }

    progressNotifier.value = 0.5;

    final allAdvances = <Advance>[];
    for (var employee in employees) {
      final advances = await _dataLoader.loadEmployeeAdvances(employee.id);
      allAdvances.addAll(advances);
    }

    progressNotifier.value = 0.7;

    final allExpenses = await _dataLoader.loadExpenses(periodStart, periodEnd);

    progressNotifier.value = 0.9;

    return await _pdfService.generateFinancialSummaryReport(
      periodTitle: periodTitle,
      periodStart: periodStart,
      periodEnd: periodEnd,
      allPayments: allPayments,
      allAdvances: allAdvances,
      allExpenses: allExpenses,
      outputDirectory: outputDirectory,
      robotoFontBytes: robotoFontBytes,
      robotoBoldFontBytes: robotoBoldFontBytes,
    );
  }
}
