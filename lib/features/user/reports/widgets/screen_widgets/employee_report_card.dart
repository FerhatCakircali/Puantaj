import 'package:flutter/material.dart';
import '../../../../../models/employee.dart';
import '../../../../../screens/constants/colors.dart';

/// Çalışan rapor kartı - Modern tasarım
class EmployeeReportCard extends StatelessWidget {
  final Employee employee;
  final Map<String, dynamic> stats;
  final VoidCallback onTap;
  final bool isTablet;

  const EmployeeReportCard({
    super.key,
    required this.employee,
    required this.stats,
    required this.onTap,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fontSize = isTablet ? 18.0 : 16.0;

    final fullDays = stats['fullDays'] ?? 0;
    final halfDays = stats['halfDays'] ?? 0;
    final absentDays = stats['absentDays'] ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee Name and Title
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryIndigo,
                        primaryIndigo.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      employee.name.isNotEmpty
                          ? employee.name[0].toUpperCase()
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
                        employee.name,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (employee.title.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          employee.title,
                          style: TextStyle(
                            fontSize: fontSize * 0.875,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.grey.shade400,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Attendance Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatChip(
                    context: context,
                    label: 'Tam',
                    value: fullDays,
                    color: const Color(0xFF4F5FBF), // Koyu mavi
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip(
                    context: context,
                    label: 'Yarım',
                    value: halfDays,
                    color: const Color(0xFF8B9FE8), // Açık mavi
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip(
                    context: context,
                    label: 'Gelmedi',
                    value: absentDays,
                    color: const Color(0xFFE89595), // Açık kırmızı
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required BuildContext context,
    required String label,
    required int value,
    required Color color,
    required bool isDark,
  }) {
    final dates = _getDatesForLabel(label);

    return GestureDetector(
      onTap: dates.isNotEmpty
          ? () {
              _showDatesDialog(context, label, dates, color, isDark);
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          boxShadow: dates.isNotEmpty
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1.0,
                  ),
                ),
                if (dates.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.visibility_outlined,
                    size: 14,
                    color: color.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DateTime> _getDatesForLabel(String label) {
    if (label == 'Tam') {
      return List<DateTime>.from(stats['fullDayDates'] ?? []);
    } else if (label == 'Yarım') {
      return List<DateTime>.from(stats['halfDayDates'] ?? []);
    } else if (label == 'Gelmedi') {
      return List<DateTime>.from(stats['absentDayDates'] ?? []);
    }
    return [];
  }

  void _showDatesDialog(
    BuildContext context,
    String label,
    List<DateTime> dates,
    Color color,
    bool isDark,
  ) {
    IconData icon;
    String title;

    if (label == 'Tam') {
      icon = Icons.wb_sunny;
      title = 'Tam Gün Çalıştığı Günler';
    } else if (label == 'Yarım') {
      icon = Icons.wb_twilight;
      title = 'Yarım Gün Çalıştığı Günler';
    } else {
      icon = Icons.cancel_outlined;
      title = 'Gelmediği Günler';
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF0A0E1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
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
              ),
              Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: color),
                          const SizedBox(width: 12),
                          Text(
                            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
