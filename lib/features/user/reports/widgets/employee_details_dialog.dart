import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/employee.dart';
import '../../../../screens/constants/colors.dart';
import '../../../../shared/widgets/dialog/dialog_handle_bar.dart';
import 'employee_details/index.dart';
import 'employee_details_dialog/controllers/employee_details_controller.dart';
import 'employee_details_dialog/handlers/attendance_data_loader.dart';
import 'employee_details_dialog/handlers/pdf_report_handler.dart';

/// Çalışan detay dialog'u
///
/// Çalışanın devam ve ödeme bilgilerini gösterir.
/// PDF rapor oluşturma özelliği sunar.
class EmployeeDetailsDialog extends StatefulWidget {
  final Employee employee;
  final VoidCallback onPaymentComplete;

  const EmployeeDetailsDialog({
    super.key,
    required this.employee,
    required this.onPaymentComplete,
  });

  /// Dialog'u modal bottom sheet olarak gösterir
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
  late final EmployeeDetailsController _controller;
  late final AttendanceDataLoader _dataLoader;
  late final PdfReportHandler _pdfHandler;

  @override
  void initState() {
    super.initState();
    _controller = EmployeeDetailsController();
    _dataLoader = AttendanceDataLoader();
    _pdfHandler = PdfReportHandler();
    _loadAttendanceData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceData() async {
    final data = await _dataLoader.loadEmployeeData(widget.employee);

    if (mounted) {
      _controller.updateAttendanceData(
        fullDays: data.attendanceResult.fullDays,
        halfDays: data.attendanceResult.halfDays,
        absentDays: data.attendanceResult.absentDays,
        fullDayDates: data.attendanceResult.fullDayDates,
        halfDayDates: data.attendanceResult.halfDayDates,
        absentDayDates: data.attendanceResult.absentDayDates,
      );

      _controller.updatePaymentData(
        totalPaid: data.totalPaid,
        paidFullDays: data.paidFullDays,
        paidHalfDays: data.paidHalfDays,
      );

      _controller.setLoading(false);
    }
  }

  Future<void> _createEmployeeReport() async {
    if (_controller.isGeneratingReport) return;

    _controller.setGeneratingReport(true);

    await _pdfHandler.generateEmployeeReport(context, widget.employee);

    if (mounted) {
      _controller.setGeneratingReport(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0A0E1A) : Colors.white;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
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
              DialogHandleBar(
                screenWidth: screenWidth,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 16),
              _buildHeader(isDark),
              const SizedBox(height: 16),
              Expanded(
                child: _controller.isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: primaryIndigo),
                      )
                    : _buildContent(isDark),
              ),
              _buildBottomButton(isDark),
            ],
          ),
        );
      },
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
                  value: '${_controller.fullDays}',
                  color: const Color(0xFF4F5FBF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: EmployeeStatCard(
                  icon: Icons.wb_twilight,
                  label: 'Yarım',
                  value: '${_controller.halfDays}',
                  color: const Color(0xFF8B9FE8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: EmployeeStatCard(
                  icon: Icons.cancel_outlined,
                  label: 'Gelmedi',
                  value: '${_controller.absentDays}',
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
          if (_controller.fullDayDates.isNotEmpty)
            EmployeeDayExpansion(
              title: 'Geldiği Günler (Tam)',
              dates: _controller.fullDayDates,
              icon: Icons.wb_sunny,
              color: const Color(0xFF4F5FBF),
            ),
          if (_controller.halfDayDates.isNotEmpty)
            EmployeeDayExpansion(
              title: 'Geldiği Günler (Yarım)',
              dates: _controller.halfDayDates,
              icon: Icons.wb_twilight,
              color: const Color(0xFF8B9FE8),
            ),
          if (_controller.absentDayDates.isNotEmpty)
            EmployeeDayExpansion(
              title: 'Gelmediği Günler',
              dates: _controller.absentDayDates,
              icon: Icons.cancel_outlined,
              color: const Color(0xFFE89595),
            ),
          if (_controller.totalPaid > 0) ...[
            const SizedBox(height: 16),
            EmployeeTotalPaidCard(
              totalPaid: _controller.totalPaid,
              paidFullDays: _controller.paidFullDays,
              paidHalfDays: _controller.paidHalfDays,
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
          onPressed: _controller.isGeneratingReport
              ? null
              : _createEmployeeReport,
          style: FilledButton.styleFrom(
            backgroundColor: primaryIndigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            elevation: 0,
          ),
          icon: _controller.isGeneratingReport
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
            _controller.isGeneratingReport
                ? 'Rapor Oluşturuluyor...'
                : 'Rapor Oluştur',
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
