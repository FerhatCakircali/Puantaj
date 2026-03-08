import 'package:flutter/material.dart';
import '../../../../../../models/employee.dart';
import '../../../../../../services/attendance_service.dart';
import '../../../../../../services/payment_service.dart';
import '../../../../../../services/advance_service.dart';
import '../../../../services/pdf_service.dart';
import '../../../../../../screens/constants/colors.dart';

/// PDF rapor oluşturma işlemlerini yönetir
///
/// Çalışan raporu oluşturma ve kullanıcıya bildirim gösterme sorumluluğunu taşır.
class PdfReportHandler {
  final PdfService _pdfService;
  final AttendanceService _attendanceService;
  final PaymentService _paymentService;
  final AdvanceService _advanceService;

  PdfReportHandler({
    PdfService? pdfService,
    AttendanceService? attendanceService,
    PaymentService? paymentService,
    AdvanceService? advanceService,
  }) : _pdfService = pdfService ?? PdfService(),
       _attendanceService = attendanceService ?? AttendanceService(),
       _paymentService = paymentService ?? PaymentService(),
       _advanceService = advanceService ?? AdvanceService();

  /// Çalışan için PDF raporu oluşturur
  Future<void> generateEmployeeReport(
    BuildContext context,
    Employee employee,
  ) async {
    try {
      final attendances = await _attendanceService.getAttendanceBetween(
        employee.startDate,
        DateTime.now(),
        workerId: employee.id,
      );
      final payments = await _paymentService.getPaymentsByWorkerId(employee.id);
      final advances = await _advanceService.getWorkerAdvances(employee.id);

      await _pdfService.generateEmployeeReport(
        employee,
        attendances,
        payments,
        advances,
      );

      if (context.mounted) {
        _showSuccessSnackBar(context);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, e);
      }
    }
  }

  void _showSuccessSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Rapor başarıyla oluşturuldu'),
        backgroundColor: primaryIndigo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rapor oluşturulurken hata oluştu: $error'),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}
