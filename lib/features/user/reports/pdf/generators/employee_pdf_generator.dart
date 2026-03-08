import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../models/employee.dart';
import '../../../services/pdf_service.dart';
import '../helpers/pdf_data_loader.dart';

/// Çalışan raporu PDF oluşturucu
///
/// Tek bir çalışan için dönemsel rapor oluşturur.
class EmployeePdfGenerator {
  final PdfService _pdfService;
  final PdfDataLoader _dataLoader;

  EmployeePdfGenerator({PdfService? pdfService, PdfDataLoader? dataLoader})
    : _pdfService = pdfService ?? PdfService(),
      _dataLoader = dataLoader ?? PdfDataLoader();

  /// Çalışan raporu oluştur
  Future<File> generate({
    required Employee employee,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String periodTitle,
    required String outputDirectory,
    required ValueNotifier<double> progressNotifier,
  }) async {
    progressNotifier.value = 0.25;

    final attendances = await _dataLoader.loadEmployeeAttendances(
      employee.id,
      periodStart,
      periodEnd,
    );

    final payments = await _dataLoader.loadEmployeePayments(employee.id);
    final advances = await _dataLoader.loadEmployeeAdvances(employee.id);

    return await _pdfService.generatePeriodEmployeeReportWithProgress(
      employee: employee,
      periodStart: periodStart,
      periodEnd: periodEnd,
      attendances: attendances,
      payments: payments,
      advances: advances,
      periodTitle: periodTitle,
      progressCallback: (progress) {
        progressNotifier.value = 0.25 + (progress * 0.75);
      },
      outputDirectory: outputDirectory,
    );
  }
}
