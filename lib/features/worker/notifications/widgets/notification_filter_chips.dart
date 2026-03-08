import 'package:flutter/material.dart';
import '../models/notification_filter.dart';

/// Bildirim filtreleme chip'leri
class NotificationFilterChips extends StatelessWidget {
  final NotificationReadFilter selectedReadFilter;
  final NotificationTypeFilter selectedTypeFilter;
  final ValueChanged<NotificationReadFilter> onReadFilterChanged;
  final ValueChanged<NotificationTypeFilter> onTypeFilterChanged;

  const NotificationFilterChips({
    super.key,
    required this.selectedReadFilter,
    required this.selectedTypeFilter,
    required this.onReadFilterChanged,
    required this.onTypeFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(left: w * 0.04, top: h * 0.01, bottom: h * 0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...NotificationReadFilter.values.map(
                    (filter) => Padding(
                      padding: EdgeInsets.only(right: w * 0.02),
                      child: _FilterChip(
                        label: filter.label,
                        isSelected: selectedReadFilter == filter,
                        onTap: () => onReadFilterChanged(filter),
                        isDark: isDark,
                      ),
                    ),
                  ),
                  SizedBox(width: w * 0.02),
                ],
              ),
            ),
          ),
          SizedBox(height: h * 0.01),
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...NotificationTypeFilter.values.map(
                    (filter) => Padding(
                      padding: EdgeInsets.only(right: w * 0.02),
                      child: _TypeChip(
                        icon: filter.icon,
                        label: filter.label,
                        isSelected: selectedTypeFilter == filter,
                        onTap: () => onTypeFilterChanged(filter),
                        isDark: isDark,
                      ),
                    ),
                  ),
                  SizedBox(width: w * 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    const primaryColor = Color(0xFF4338CA);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(w * 0.05),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.01),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(w * 0.05),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: w * 0.035,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _TypeChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    const primaryColor = Color(0xFF4338CA);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(w * 0.05),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.035,
          vertical: h * 0.008,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.15)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(w * 0.05),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade200),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: w * 0.04,
              color: isSelected
                  ? primaryColor
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.grey.shade600),
            ),
            SizedBox(width: w * 0.015),
            Text(
              label,
              style: TextStyle(
                fontSize: w * 0.032,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? primaryColor
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
