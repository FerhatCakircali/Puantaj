import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../screens/constants/colors.dart';

/// Rapor dönemi seçim kartı - Modern tasarım
class PeriodSelectionCard extends StatelessWidget {
  final ReportPeriod selectedPeriodType;
  final DateTime customStartDate;
  final DateTime customEndDate;
  final Function(ReportPeriod) onPeriodChanged;
  final Future<void> Function(bool isStartDate) onSelectCustomDate;

  const PeriodSelectionCard({
    super.key,
    required this.selectedPeriodType,
    required this.customStartDate,
    required this.customEndDate,
    required this.onPeriodChanged,
    required this.onSelectCustomDate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final periods = [
      {'value': ReportPeriod.daily, 'label': 'Günlük', 'icon': Icons.today},
      {
        'value': ReportPeriod.weekly,
        'label': 'Haftalık',
        'icon': Icons.view_week,
      },
      {
        'value': ReportPeriod.monthly,
        'label': 'Aylık',
        'icon': Icons.calendar_month,
      },
      {
        'value': ReportPeriod.quarterly,
        'label': 'Üç Aylık',
        'icon': Icons.calendar_view_month,
      },
      {
        'value': ReportPeriod.yearly,
        'label': 'Yıllık',
        'icon': Icons.calendar_today,
      },
      {
        'value': ReportPeriod.custom,
        'label': 'Özel Tarih',
        'icon': Icons.date_range,
      },
    ];

    return Container(
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: primaryIndigo,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Rapor Dönemi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.8,
            ),
            itemCount: periods.length,
            itemBuilder: (context, index) {
              final period = periods[index];
              final isSelected = selectedPeriodType == period['value'];
              return GestureDetector(
                onTap: () => onPeriodChanged(period['value'] as ReportPeriod),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryIndigo
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? primaryIndigo
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey.shade300),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        period['icon'] as IconData,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : Colors.grey.shade700),
                      ),
                      const SizedBox(height: 3),
                      Flexible(
                        child: Text(
                          period['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (selectedPeriodType == ReportPeriod.custom) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    context,
                    isDark,
                    'Başlangıç',
                    customStartDate,
                    () => onSelectCustomDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateButton(
                    context,
                    isDark,
                    'Bitiş',
                    customEndDate,
                    () => onSelectCustomDate(false),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateButton(
    BuildContext context,
    bool isDark,
    String label,
    DateTime date,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: primaryIndigo,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(date),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
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

/// Rapor dönem tipleri
enum ReportPeriod { daily, weekly, monthly, quarterly, yearly, custom }
