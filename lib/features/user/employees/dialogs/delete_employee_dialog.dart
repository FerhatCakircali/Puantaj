import 'package:flutter/material.dart';
import '../../../../models/employee.dart';
import '../../../../services/attendance_service.dart';
import '../../../../services/payment_service.dart';
import '../../../../services/advance_service.dart';
import '../../services/pdf_service.dart';

/// Çalışan silme dialog'u
class DeleteEmployeeDialog extends StatelessWidget {
  final Employee employee;
  final Future<void> Function(int employeeId) onDelete;
  final VoidCallback onComplete;

  const DeleteEmployeeDialog({
    super.key,
    required this.employee,
    required this.onDelete,
    required this.onComplete,
  });

  /// Dialog'u göster
  static Future<void> show(
    BuildContext context, {
    required Employee employee,
    required Future<void> Function(int employeeId) onDelete,
    required VoidCallback onComplete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true, // Navigation bar'dan korunur
      backgroundColor: Colors.transparent,
      builder: (context) => DeleteEmployeeDialog(
        employee: employee,
        onDelete: onDelete,
        onComplete: onComplete,
      ),
    );
  }

  Future<void> _handleDeleteWithReport(BuildContext context) async {
    Navigator.pop(context);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final pdf = PdfService();
    final attendanceService = AttendanceService();
    final paymentService = PaymentService();
    final advanceService = AdvanceService();

    try {
      debugPrint('📄 DeleteEmployeeDialog: Rapor oluşturuluyor');

      final attendances = await attendanceService.getAttendanceBetween(
        employee.startDate,
        DateTime.now(),
        workerId: employee.id,
      );

      final payments = await paymentService.getPaymentsByWorkerId(employee.id);
      final advances = await advanceService.getWorkerAdvances(employee.id);

      final pdfFile = await pdf.generateEmployeeTerminatedReport(
        employee,
        attendances,
        payments,
        advances,
      );

      await onDelete(employee.id);
      onComplete();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            '${employee.name} silindi, rapor kaydedildi: ${pdfFile.path}',
          ),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'RAPORU AÇ',
            onPressed: () => pdf.openPdf(pdfFile),
          ),
        ),
      );

      debugPrint('✅ DeleteEmployeeDialog: Çalışan raporla silindi');
    } catch (e) {
      debugPrint('❌ DeleteEmployeeDialog: Hata: $e');

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('İşlem sırasında bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDeleteOnly(BuildContext context) async {
    Navigator.pop(context);

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      debugPrint('🗑️ DeleteEmployeeDialog: Çalışan siliniyor (raporsuz)');

      await onDelete(employee.id);
      onComplete();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('${employee.name} silindi.'),
          backgroundColor: Colors.green,
        ),
      );

      debugPrint('✅ DeleteEmployeeDialog: Çalışan silindi');
    } catch (e) {
      debugPrint('❌ DeleteEmployeeDialog: Hata: $e');

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('İşlem sırasında bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 24),
                // Title
                Text(
                  '${employee.name} Silinecek',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                // Description
                Text(
                  'Bu çalışanı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                // Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _handleDeleteWithReport(context),
                      icon: Icon(Icons.picture_as_pdf, size: 18),
                      label: Text(
                        'Raporla ve Sil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _handleDeleteOnly(context),
                      icon: Icon(Icons.delete_outline, size: 18),
                      label: Text(
                        'Sadece Sil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: BorderSide(color: Colors.orange, width: 2),
                        padding: EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('İptal'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
