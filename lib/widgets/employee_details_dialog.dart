import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../models/attendance.dart' as attendance;
import '../services/attendance_service.dart';
import '../services/pdf_service.dart';
import '../services/payment_service.dart';

class EmployeeDetailsDialog extends StatefulWidget {
  final Employee employee;
  final VoidCallback onPaymentComplete;

  const EmployeeDetailsDialog({
    Key? key,
    required this.employee,
    required this.onPaymentComplete,
  }) : super(key: key);

  @override
  State<EmployeeDetailsDialog> createState() => _EmployeeDetailsDialogState();
}

class _EmployeeDetailsDialogState extends State<EmployeeDetailsDialog> {
  bool _isLoading = true;
  List<attendance.Attendance> _attendanceRecords = [];
  int _fullDays = 0;
  int _halfDays = 0;
  int _absentDays = 0;
  List<DateTime> _fullDayDates = [];
  List<DateTime> _halfDayDates = [];
  List<DateTime> _absentDayDates = [];
  final PdfService _pdfService = PdfService();
  final AttendanceService _attendanceService = AttendanceService();
  final PaymentService _paymentService = PaymentService();

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

    // Giriş tarihinden bugüne kadar olan tüm günleri kontrol et
    DateTime currentDate = widget.employee.startDate;
    while (!currentDate.isAfter(DateTime.now())) {
      // O güne ait yevmiye kaydı var mı kontrol et
      final record = records.firstWhere(
        (r) =>
            r.date.year == currentDate.year &&
            r.date.month == currentDate.month &&
            r.date.day == currentDate.day,
        orElse:
            () => attendance.Attendance(
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

    setState(() {
      _attendanceRecords = records;
      _isLoading = false;
    });
  }

  Future<void> _createEmployeeReport() async {
    try {
      final attendances = await _attendanceService.getAttendanceBetween(
        widget.employee.startDate,
        DateTime.now(),
        workerId: widget.employee.id,
      );
      final payments = await _paymentService.getPaymentsByWorkerId(
        widget.employee.id,
      );
      await _pdfService.generateEmployeeReport(
        widget.employee,
        attendances,
        payments,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapor başarıyla oluşturuldu')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rapor oluşturulurken hata oluştu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final padding = isTablet ? 32.0 : 16.0;
    final fontSize = isTablet ? 18.0 : 14.0;
    final avatarRadius = isTablet ? 36.0 : 28.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: isTablet ? 600 : double.infinity,
        padding: EdgeInsets.all(padding),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: avatarRadius,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.employee.name,
                          style: TextStyle(
                            fontSize: fontSize * 1.6,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.employee.title.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.employee.title,
                              style: TextStyle(
                                fontSize: fontSize,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Kapat',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Rapor Oluştur'),
                  onPressed: _createEmployeeReport,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                // Bilgi Kartları
                Wrap(
                  runSpacing: 12,
                  spacing: 12,
                  children: [
                    _InfoCard(
                      icon: Icons.phone,
                      label: 'Telefon',
                      value: widget.employee.phone,
                    ),
                    _InfoCard(
                      icon: Icons.calendar_today,
                      label: 'Giriş Tarihi',
                      value: DateFormat(
                        'dd/MM/yyyy',
                      ).format(widget.employee.startDate),
                    ),
                    _InfoCard(
                      icon: Icons.check_circle,
                      label: 'Geldiği Gün',
                      value: '$_fullDays Tam',
                      color: Colors.green[100],
                      iconColor: Colors.green[700],
                    ),
                    _InfoCard(
                      icon: Icons.timelapse,
                      label: 'Yarım Gün',
                      value: '$_halfDays',
                      color: Colors.orange[100],
                      iconColor: Colors.orange[700],
                    ),
                    _InfoCard(
                      icon: Icons.cancel,
                      label: 'Gelmediği Gün',
                      value: '$_absentDays',
                      color: Colors.red[100],
                      iconColor: Colors.red[700],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Gün Listeleri (ExpansionTile)
                _buildDayExpansion(
                  context,
                  _fullDayDates,
                  'Geldiği Günlerin Tarihi (Tam)',
                  Icons.check_circle,
                  Colors.green[700],
                ),
                _buildDayExpansion(
                  context,
                  _halfDayDates,
                  'Geldiği Günlerin Tarihi (Yarım)',
                  Icons.timelapse,
                  Colors.orange[700],
                ),
                _buildDayExpansion(
                  context,
                  _absentDayDates,
                  'Gelmediği Günlerin Tarihi',
                  Icons.cancel,
                  Colors.red[700],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayExpansion(
    BuildContext context,
    List<DateTime> dates,
    String title,
    IconData icon,
    Color? iconColor,
  ) {
    if (dates.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  dates
                      .map(
                        (date) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(DateFormat('dd/MM/yyyy').format(date)),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final Color? iconColor;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.iconColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    Color? effectiveColor = color;
    Color? effectiveIconColor = iconColor;
    // Renkleri temaya göre ayarla
    if (color == Colors.green[100]) {
      effectiveColor =
          isDark ? Colors.green[900]?.withOpacity(0.25) : Colors.green[100];
      effectiveIconColor = isDark ? Colors.green[300] : Colors.green[700];
    } else if (color == Colors.orange[100]) {
      effectiveColor =
          isDark ? Colors.orange[900]?.withOpacity(0.25) : Colors.orange[100];
      effectiveIconColor = isDark ? Colors.orange[300] : Colors.orange[700];
    } else if (color == Colors.red[100]) {
      effectiveColor =
          isDark ? Colors.red[900]?.withOpacity(0.25) : Colors.red[100];
      effectiveIconColor = isDark ? Colors.red[300] : Colors.red[700];
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: effectiveColor ?? theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 180),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: effectiveIconColor ?? theme.colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
