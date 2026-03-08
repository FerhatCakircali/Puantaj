import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../../models/payment.dart';
import '../../../../../models/advance.dart';
import '../../../../../models/expense.dart';
import 'financial_summary/pdf_financial_summary_service.dart';

/// Finansal özet raporu PDF oluşturma servisi (Wrapper - Backward Compatibility)
///
/// Bu sınıf geriye dönük uyumluluk için korunmuştur.
/// Tüm işlevsellik [PdfFinancialSummaryService]'e taşınmıştır.
@Deprecated('Use PdfFinancialSummaryService directly')
class PdfFinancialSummaryReportService {
  final PdfFinancialSummaryService _service = PdfFinancialSummaryService();

  Future<File> generate({
    required String periodTitle,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Payment> allPayments,
    required List<Advance> allAdvances,
    required List<Expense> allExpenses,
    String? outputDirectory,
    Uint8List? robotoFontBytes,
    Uint8List? robotoBoldFontBytes,
  }) async {
    return _service.generate(
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
