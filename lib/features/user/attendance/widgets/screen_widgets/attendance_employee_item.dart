import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../models/employee.dart';
import '../../../../../models/attendance.dart' as attendance;

/// Çalışan listesi item widget'ı
class AttendanceEmployeeItem extends StatelessWidget {
  final Employee employee;
  final DateTime selectedDate;
  final attendance.AttendanceStatus currentStatus;
  final ValueChanged<attendance.AttendanceStatus> onStatusChanged;

  const AttendanceEmployeeItem({
    super.key,
    required this.employee,
    required this.selectedDate,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final fontSize = isTablet ? 22.0 : 16.0;
    final isBeforeStartDate = selectedDate.isBefore(employee.startDate);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.22
                    : 0.12,
              ),
              child: Text(
                employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (employee.title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        employee.title,
                        style: TextStyle(
                          fontSize: fontSize * 0.85,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  // İşe başlama tarihinden önce ise uyarı göster
                  if (isBeforeStartDate)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              'İşe başlama: ${DateFormat('dd/MM/yyyy').format(employee.startDate)}',
                              style: TextStyle(
                                fontSize: fontSize * 0.7,
                                color: Colors.orange,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<attendance.AttendanceStatus>(
              value: currentStatus,
              onChanged: isBeforeStartDate
                  ? null // İşe başlama tarihinden önce ise değiştirilemez
                  : (attendance.AttendanceStatus? value) {
                      if (value != null) {
                        onStatusChanged(value);
                      }
                    },
              borderRadius: BorderRadius.circular(12),
              isDense: true,
              icon: const Icon(Icons.arrow_drop_down, size: 18),
              style: TextStyle(
                fontSize: fontSize * 0.85,
                color: isBeforeStartDate
                    ? Colors
                          .grey // İşe başlama tarihinden önce ise gri renk
                    : Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              underline: const SizedBox(),
              items: [
                DropdownMenuItem<attendance.AttendanceStatus>(
                  value: attendance.AttendanceStatus.absent,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.close,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Gelmedi',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          fontSize: fontSize * 0.85,
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem<attendance.AttendanceStatus>(
                  value: attendance.AttendanceStatus.fullDay,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tam',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          fontSize: fontSize * 0.85,
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem<attendance.AttendanceStatus>(
                  value: attendance.AttendanceStatus.halfDay,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.adjust,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Yarım',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          fontSize: fontSize * 0.85,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
