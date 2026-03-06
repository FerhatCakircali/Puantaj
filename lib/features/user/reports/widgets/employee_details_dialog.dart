import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/employee.dart';
import '../../../../models/attendance.dart' as attendance;
import '../../../../services/attendance_service.dart';
import '../../../../services/advance_service.dart';
import '../../services/pdf_service.dart';
import '../../../../services/payment_service.dart';
import '../../../../screens/constants/colors.dart';
import 'employee_details/index.dart';

/// Çalışan detay dialog'u
/// Çalışanın devam ve ödeme bilgilerini gösterir
class EmployeeDetailsDialog extends StatefulWidget {
  final Employee employee;
  final VoidCallback onPaymentComplete;

  const EmployeeDetailsDialog({
    super.key,
    required this.employee,
    required this.onPaymentComplete,
  });

  static void show(
    BuildContext context, {
    required Employee employee,
    required VoidCallback onPaymentComplete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
            isDismissible: true,
      enableDrag: true,
      builder: (context) => EmployeeDetailsDialog(
        employee: employee,
        onPaymentComplete: onPaymentComplete,
      ),
    );
  }

  @override
  State<EmployeeDetailsDialog> createState() => _EmployeeDetailsDialogState();
}

class _EmployeeDetailsDialogState extends State<EmployeeDetailsDialog> {
  bool _isLoading = true;
  bool _isGeneratingReport = false;
  int _fullDays = 0;
  int _halfDays = 0;
  int _absentDays = 0;
  List<DateTime> _fullDayDates = [];
  List<DateTime> _halfDayDates = [];
  List<DateTime> _absentDayDates = [];
  double _totalPaid = 0.0;
  int _paidFullDays = 0;
  int _paidHalfDays = 0;
  final PdfService _pdfService = PdfService();
  final AttendanceService _attendanceService = AttendanceService();
  final PaymentService _paymentService = PaymentService();
  final AdvanceService _advanceService = AdvanceService();

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    final records = await AttendanceService().getAttendanceBetween(
      widget.employee.startDate,
      DateTime.now(),
      workerId: widget.employee.id,
    );

    _fullDays = 0;
    _halfDays = 0;
    _absentDays = 0;
    _fullDayDates = [];
    _halfDayDates = [];
    _absentDayDates = [];

    DateTime currentDate = widget.employee.startDate;
    while (!currentDate.isAfter(DateTime.now())) {
      final record = records.firstWhere(
        (r) =>
            r.date.year == currentDate.year &&
            r.date.month == currentDate.month &&
            r.date.day == currentDate.day,
        orElse: () => attendance.Attendance(
          userId: 0,
          workerId: widget.employee.id,
          date: currentDate,
          status: attendance.AttendanceStatus.absent,
        ),
      );

      switch (record.status) {
        case attendance.AttendanceStatus.fullDay:
          _fullDays++;
          _fullDayDates.add(currentDate);
          break;
        case attendance.AttendanceStatus.halfDay:
          _halfDays++;
          _halfDayDates.add(currentDate);
          break;
        case attendance.AttendanceStatus.absent:
          _absentDays++;
          _absentDayDates.add(currentDate);
          break;
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    final payments = await _paymentService.getPaymentsByWorkerId(
      widget.employee.id,
    );
    _totalPaid = payments.fold(0.0, (sum, payment) => sum + payment.amount);
    _paidFullDays = payments.fold(0, (sum, payment) => sum + payment.fullDays);
    _paidHalfDays = payments.fold(0, (sum, payment) => sum + payment.halfDays);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createEmployeeReport() async {
    if (_isGeneratingReport) return;

    setState(() => _isGeneratingReport = true);

    try {
      final attendances = await _attendanceService.getAttendanceBetween(
        widget.employee.startDate,
        DateTime.now(),
        workerId: widget.employee.id,
      );
      final payments = await _paymentService.getPaymentsByWorkerId(
        widget.employee.id,
      );
      final advances = await _advanceService.getWorkerAdvances(
        widget.employee.id,
      );
      await _pdfService.generateEmployeeReport(
        widget.employee,
        attendances,
        payments,
        advances,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rapor başarıyla oluşturuldu'),
            backgroundColor: primaryIndigo,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapor oluşturulurken hata oluştu: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingReport = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0A0E1A) : Colors.white;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          _buildDragHandle(isDark),
          const SizedBox(height: 16),
          _buildHeader(isDark),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryIndigo))
                : _buildContent(isDark),
          ),
          _buildBottomButton(isDark),
        ],
      ),
    );
  }

  Widget _buildDragHandle(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryIndigo, primaryIndigo.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryIndigo.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.employee.name.isNotEmpty
                    ? widget.employee.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.employee.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                if (widget.employee.title.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.employee.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: EmployeeStatCard(
                  icon: Icons.wb_sunny,
                  label: 'Tam Gün',
                  value: '$_fullDays',
                  color: const Color(0xFF4F5FBF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: EmployeeStatCard(
                  icon: Icons.wb_twilight,
                  label: 'Yarım',
                  value: '$_halfDays',
                  color: const Color(0xFF8B9FE8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: EmployeeStatCard(
                  icon: Icons.cancel_outlined,
                  label: 'Gelmedi',
                  value: '$_absentDays',
                  color: const Color(0xFFE89595),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          EmployeeInfoRow(
            icon: Icons.phone_outlined,
            label: 'Telefon',
            value: widget.employee.phone,
          ),
          const SizedBox(height: 12),
          EmployeeInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Giriş Tarihi',
            value: DateFormat('dd/MM/yyyy').format(widget.employee.startDate),
          ),
          const SizedBox(height: 16),
          if (_fullDayDates.isNotEmpty)
            EmployeeDayExpansion(
              title: 'Geldiği Günler (Tam)',
              dates: _fullDayDates,
              icon: Icons.wb_sunny,
              color: const Color(0xFF4F5FBF),
            ),
          if (_halfDayDates.isNotEmpty)
            EmployeeDayExpansion(
              title: 'Geldiği Günler (Yarım)',
              dates: _halfDayDates,
              icon: Icons.wb_twilight,
              color: const Color(0xFF8B9FE8),
            ),
          if (_absentDayDates.isNotEmpty)
            EmployeeDayExpansion(
              title: 'Gelmediği Günler',
              dates: _absentDayDates,
              icon: Icons.cancel_outlined,
              color: const Color(0xFFE89595),
            ),
          if (_totalPaid > 0) ...[
            const SizedBox(height: 16),
            EmployeeTotalPaidCard(
              totalPaid: _totalPaid,
              paidFullDays: _paidFullDays,
              paidHalfDays: _paidHalfDays,
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBottomButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.grey.shade50,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.icon(
          onPressed: _isGeneratingReport ? null : _createEmployeeReport,
          style: FilledButton.styleFrom(
            backgroundColor: primaryIndigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            elevation: 0,
          ),
          icon: _isGeneratingReport
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.picture_as_pdf, size: 20),
          label: Text(
            _isGeneratingReport ? 'Rapor Oluşturuluyor...' : 'Rapor Oluştur',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
