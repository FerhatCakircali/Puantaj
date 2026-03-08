import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';
import 'worker_stat_row.dart';
import 'worker_dates_list.dart';

/// Aylık istatistikleri gösteren kart widget'ı
class WorkerMonthCard extends StatefulWidget {
  final Map<String, dynamic> monthlyStats;
  final double attendanceRate;
  final double monthlyAdvances;

  const WorkerMonthCard({
    super.key,
    required this.monthlyStats,
    required this.attendanceRate,
    this.monthlyAdvances = 0.0,
  });

  @override
  State<WorkerMonthCard> createState() => _WorkerMonthCardState();
}

class _WorkerMonthCardState extends State<WorkerMonthCard> {
  bool _fullDayExpanded = false;
  bool _halfDayExpanded = false;
  bool _absentExpanded = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fullDays = widget.monthlyStats['total_full_days'] ?? 0;
    final halfDays = widget.monthlyStats['total_half_days'] ?? 0;
    final absentDays = widget.monthlyStats['total_absent_days'] ?? 0;
    final monthlyAmount = widget.monthlyStats['total_amount'] ?? 0.0;

    final fullDayDates = List<String>.from(
      widget.monthlyStats['full_day_dates'] ?? [],
    );
    final halfDayDates = List<String>.from(
      widget.monthlyStats['half_day_dates'] ?? [],
    );
    final absentDates = List<String>.from(
      widget.monthlyStats['absent_dates'] ?? [],
    );

    const primaryColor = Color(0xFF4338CA);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.06),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.025),
                decoration: BoxDecoration(
                  color: isDark
                      ? primaryColor.withValues(alpha: 0.2)
                      : primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_month,
                  color: primaryColor,
                  size: w * 0.06,
                ),
              ),
              SizedBox(width: w * 0.03),
              Text(
                'Bu Ay',
                style: TextStyle(
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: h * 0.025),
          // Tam Gün
          WorkerStatRow(
            icon: Icons.check_circle,
            label: 'Tam Gün',
            value: fullDays.toString(),
            color: Colors.green,
            isExpanded: _fullDayExpanded,
            onTap: fullDays > 0
                ? () => setState(() => _fullDayExpanded = !_fullDayExpanded)
                : null,
          ),
          if (_fullDayExpanded && fullDayDates.isNotEmpty)
            WorkerDatesList(
              dates: fullDayDates,
              color: Colors.green,
              label: 'Tam Gün',
            ),
          SizedBox(height: h * 0.015),
          // Yarım Gün
          WorkerStatRow(
            icon: Icons.schedule,
            label: 'Yarım Gün',
            value: halfDays.toString(),
            color: Colors.orange,
            isExpanded: _halfDayExpanded,
            onTap: halfDays > 0
                ? () => setState(() => _halfDayExpanded = !_halfDayExpanded)
                : null,
          ),
          if (_halfDayExpanded && halfDayDates.isNotEmpty)
            WorkerDatesList(
              dates: halfDayDates,
              color: Colors.orange,
              label: 'Yarım Gün',
            ),
          SizedBox(height: h * 0.015),
          // Gelmedi
          WorkerStatRow(
            icon: Icons.cancel,
            label: 'Gelmedi',
            value: absentDays.toString(),
            color: Colors.red,
            isExpanded: _absentExpanded,
            onTap: absentDays > 0
                ? () => setState(() => _absentExpanded = !_absentExpanded)
                : null,
          ),
          if (_absentExpanded && absentDates.isNotEmpty)
            WorkerDatesList(
              dates: absentDates,
              color: Colors.red,
              label: 'Gelmedi',
            ),
          SizedBox(height: h * 0.02),
          // Devam Oranı
          Container(
            padding: EdgeInsets.all(w * 0.04),
            decoration: BoxDecoration(
              color: isDark
                  ? primaryColor.withValues(alpha: 0.15)
                  : primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, size: w * 0.055, color: primaryColor),
                SizedBox(width: w * 0.025),
                Text(
                  'Devam Oranı',
                  style: TextStyle(
                    fontSize: w * 0.04,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                Text(
                  '%${widget.attendanceRate.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: w * 0.055,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: h * 0.025),
          // Bu Ay Kazanılan
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bu Ay Kazanılan',
                style: TextStyle(
                  fontSize: w * 0.04,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: h * 0.015),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: h * 0.02,
                  horizontal: w * 0.04,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            primaryColor.withValues(alpha: 0.2),
                            primaryColor.withValues(alpha: 0.1),
                          ]
                        : [
                            primaryColor.withValues(alpha: 0.12),
                            primaryColor.withValues(alpha: 0.06),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '₺${CurrencyFormatter.format(monthlyAmount + widget.monthlyAdvances)}',
                  style: TextStyle(
                    fontSize: w * 0.10,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    letterSpacing: -2,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Detay: Ödemeler ve Avanslar
              if (monthlyAmount > 0 || widget.monthlyAdvances > 0) ...[
                SizedBox(height: h * 0.015),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (monthlyAmount > 0)
                      Column(
                        children: [
                          Text(
                            'Ödemeler',
                            style: TextStyle(
                              fontSize: w * 0.032,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(height: h * 0.005),
                          Text(
                            '₺${CurrencyFormatter.format(monthlyAmount)}',
                            style: TextStyle(
                              fontSize: w * 0.038,
                              fontWeight: FontWeight.w800,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    if (widget.monthlyAdvances > 0)
                      Column(
                        children: [
                          Text(
                            'Avanslar',
                            style: TextStyle(
                              fontSize: w * 0.032,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(height: h * 0.005),
                          Text(
                            '₺${CurrencyFormatter.format(widget.monthlyAdvances)}',
                            style: TextStyle(
                              fontSize: w * 0.038,
                              fontWeight: FontWeight.w800,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
