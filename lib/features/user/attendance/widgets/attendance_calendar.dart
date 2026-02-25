import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Yatay takvim seçici widget'ı
class AttendanceCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onCalendarTap;
  final Function(DateTime) onDateSelected;

  const AttendanceCalendar({
    super.key,
    required this.selectedDate,
    required this.onCalendarTap,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 7 gün oluştur (3 önceki, seçili, 3 sonraki)
    final days = List.generate(7, (index) {
      return selectedDate.add(Duration(days: index - 3));
    });

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: theme.brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ay/Yıl Başlığı
          Padding(
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.04,
              screenHeight * 0.015,
              screenWidth * 0.04,
              screenHeight * 0.01,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    DateFormat('MMMM yyyy', 'tr_TR').format(selectedDate),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      fontSize: screenWidth * 0.05,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: onCalendarTap,
                  icon: Icon(Icons.calendar_month, size: screenWidth * 0.055),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    foregroundColor: theme.colorScheme.primary,
                    padding: EdgeInsets.all(screenWidth * 0.02),
                  ),
                ),
              ],
            ),
          ),
          // Yatay Tarih Seçici
          SizedBox(
            height: screenHeight * 0.085,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.04,
                0,
                screenWidth * 0.04,
                screenHeight * 0.015,
              ),
              itemCount: days.length,
              separatorBuilder: (_, __) => SizedBox(width: screenWidth * 0.03),
              itemBuilder: (context, index) {
                final day = days[index];
                final isSelected =
                    day.day == selectedDate.day &&
                    day.month == selectedDate.month &&
                    day.year == selectedDate.year;
                final isCurrentDay =
                    day.day == today.day &&
                    day.month == today.month &&
                    day.year == today.year;
                final isFuture = day.isAfter(
                  DateTime(today.year, today.month, today.day),
                );

                return GestureDetector(
                  onTap: isFuture ? null : () => onDateSelected(day),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: screenWidth * 0.13,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : isFuture
                          ? theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(screenWidth * 0.035),
                      border: isCurrentDay && !isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.5,
                              ),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE', 'tr_TR').format(day).toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimary.withValues(
                                    alpha: 0.7,
                                  )
                                : isFuture
                                ? theme.colorScheme.onSurface.withValues(
                                    alpha: 0.3,
                                  )
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            fontSize: screenWidth * 0.025,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.003),
                        Text(
                          '${day.day}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : isFuture
                                ? theme.colorScheme.onSurface.withValues(
                                    alpha: 0.3,
                                  )
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            fontSize: screenWidth * 0.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
