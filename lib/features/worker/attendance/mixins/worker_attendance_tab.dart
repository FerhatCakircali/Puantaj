import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'worker_attendance_helpers.dart';

/// Yevmiye geçmişi tab widget'ı
class WorkerAttendanceTab extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> attendanceHistory;
  final VoidCallback onRefresh;

  const WorkerAttendanceTab({
    super.key,
    required this.isLoading,
    required this.attendanceHistory,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryColor = Color(0xFF4338CA);

    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (attendanceHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: w * 0.15,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: h * 0.02),
            Text(
              'Kayıt bulunamadı',
              style: TextStyle(
                fontSize: w * 0.04,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(w * 0.06, h * 0.015, w * 0.06, h * 0.1),
        itemCount: attendanceHistory.length,
        itemExtent:
            110.0,         itemBuilder: (context, index) {
          final record = attendanceHistory[index];
          final date = DateTime.parse(record['attendance_date']);
          final status = record['status'] as String;
          final createdBy = record['created_by'] as String;
          final statusColor = WorkerAttendanceHelpers.getStatusColor(status);

          return Container(
            margin: EdgeInsets.only(bottom: h * 0.015),
            padding: EdgeInsets.all(w * 0.04),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar with Icon
                Container(
                  width: w * 0.12,
                  height: w * 0.12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              statusColor.withValues(alpha: 0.3),
                              statusColor.withValues(alpha: 0.2),
                            ]
                          : [
                              statusColor.withValues(alpha: 0.15),
                              statusColor.withValues(alpha: 0.1),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    WorkerAttendanceHelpers.getStatusIcon(status),
                    color: statusColor,
                    size: w * 0.06,
                  ),
                ),
                SizedBox(width: w * 0.035),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          DateFormat('dd MMM yyyy, EEEE', 'tr_TR').format(date),
                          style: TextStyle(
                            fontSize: w * 0.038,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: h * 0.003),
                      Row(
                        children: [
                          Icon(
                            createdBy == 'manager'
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            size: w * 0.032,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          SizedBox(width: w * 0.01),
                          Flexible(
                            child: Text(
                              createdBy == 'manager' ? 'Yönetici' : 'Çalışan',
                              style: TextStyle(
                                fontSize: w * 0.03,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: h * 0.002),
                      Text(
                        DateFormat(
                          'HH:mm',
                        ).format(DateTime.parse(record['created_at'])),
                        style: TextStyle(
                          fontSize: w * 0.03,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: w * 0.02),
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.025,
                    vertical: h * 0.006,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? statusColor.withValues(alpha: 0.2)
                        : statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    WorkerAttendanceHelpers.getStatusText(status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: w * 0.03,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
