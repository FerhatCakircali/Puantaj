import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Yatay takvim seçici widget'ı
class AttendanceCalendar extends StatefulWidget {
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
  State<AttendanceCalendar> createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<AttendanceCalendar> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Widget build edildikten sonra scroll pozisyonunu ayarla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  @override
  void didUpdateWidget(AttendanceCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tarih değiştiğinde scroll pozisyonunu güncelle
    if (oldWidget.selectedDate != widget.selectedDate) {
      _scrollToSelectedDate();
    }
  }

  void _scrollToSelectedDate() {
    if (_scrollController.hasClients) {
      final screenWidth = MediaQuery.of(context).size.width;
      final itemWidth =
          screenWidth * 0.13 + screenWidth * 0.03; // item width + separator
      final padding = screenWidth * 0.04;

      // Seçili gün her zaman 15. index'te (daysBefore = 15)
      final selectedIndex = 15;

      // Seçili günü ortaya getir
      final scrollPosition =
          (itemWidth * selectedIndex) -
          (screenWidth / 2) +
          (itemWidth / 2) +
          padding;
      _scrollController.animateTo(
        scrollPosition.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Solda 15 gün, sağda 15 gün
    final daysBefore = 15;
    final daysAfter = 15;

    // Toplam gün sayısı: 15 + 1 + 15 = 31 gün
    final totalDays = daysBefore + 1 + daysAfter;

    final days = List.generate(totalDays, (index) {
      return widget.selectedDate.add(Duration(days: index - daysBefore));
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
                    DateFormat(
                      'MMMM yyyy',
                      'tr_TR',
                    ).format(widget.selectedDate),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      fontSize: screenWidth * 0.05,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: widget.onCalendarTap,
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
              controller: _scrollController,
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
                    day.day == widget.selectedDate.day &&
                    day.month == widget.selectedDate.month &&
                    day.year == widget.selectedDate.year;
                final isCurrentDay =
                    day.day == today.day &&
                    day.month == today.month &&
                    day.year == today.year;
                final todayNormalized = DateTime(
                  today.year,
                  today.month,
                  today.day,
                );
                final dayNormalized = DateTime(day.year, day.month, day.day);
                final isFuture = dayNormalized.isAfter(todayNormalized);

                return Material(
                  key: ValueKey('day_${day.year}_${day.month}_${day.day}'),
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isFuture
                        ? null
                        : () {
                            debugPrint(
                              '🖱️ Tarih tıklandı: ${day.day}/${day.month}/${day.year}',
                            );
                            widget.onDateSelected(day);
                          },
                    borderRadius: BorderRadius.circular(screenWidth * 0.035),
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
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.035,
                        ),
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
                            DateFormat(
                              'EEE',
                              'tr_TR',
                            ).format(day).toUpperCase(),
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
