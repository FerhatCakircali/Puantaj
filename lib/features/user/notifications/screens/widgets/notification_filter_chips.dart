import 'package:flutter/material.dart';

/// Bildirim filtre chip'leri widget'ı
///
/// Tümü, Okunmamış ve Okunmuş filtrelerini gösterir.
class NotificationFilterChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const NotificationFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(left: w * 0.04, top: h * 0.01, bottom: h * 0.01),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterChip(w, h, isDark, label: 'Tümü', filterValue: 'all'),
              SizedBox(width: w * 0.02),
              _buildFilterChip(
                w,
                h,
                isDark,
                label: 'Okunmamış',
                filterValue: 'unread',
              ),
              SizedBox(width: w * 0.02),
              _buildFilterChip(
                w,
                h,
                isDark,
                label: 'Okunmuş',
                filterValue: 'read',
              ),
              SizedBox(width: w * 0.04),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    double w,
    double h,
    bool isDark, {
    required String label,
    required String filterValue,
  }) {
    const primaryColor = Color(0xFF4338CA);
    final isSelected = selectedFilter == filterValue;

    return InkWell(
      onTap: () => onFilterChanged(filterValue),
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
