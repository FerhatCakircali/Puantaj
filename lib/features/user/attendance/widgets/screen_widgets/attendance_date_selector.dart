import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Tarih seçici widget'ı - önceki/sonraki gün navigasyonu ve tarih seçici
class AttendanceDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onSelectDate;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback? onSave;
  final VoidCallback? onSendReminders;
  final bool hasPendingChanges;

  const AttendanceDateSelector({
    super.key,
    required this.selectedDate,
    required this.onSelectDate,
    required this.onPreviousDay,
    required this.onNextDay,
    this.onSave,
    this.onSendReminders,
    required this.hasPendingChanges,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final fontSize = isTablet ? 22.0 : 16.0;
    final formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Sol taraf - önceki gün butonu ve takvim ikonu
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: onPreviousDay,
                    tooltip: 'Önceki Gün',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 22,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                ],
              ),

              // Orta - tarih seçici
              Flexible(
                child: GestureDetector(
                  onTap: onSelectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            formattedDate,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize * 0.85,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.primary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Sağ taraf - sonraki gün butonu, hatırlatma butonu ve kaydet butonu
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: onNextDay,
                    tooltip: 'Sonraki Gün',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 22,
                    visualDensity: VisualDensity.compact,
                  ),
                  if (onSendReminders != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.notifications_active),
                      tooltip: 'Yevmiye Hatırlatması Gönder',
                      onPressed: onSendReminders,
                      color: Colors.orange,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 22,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                  if (hasPendingChanges && onSave != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.save),
                      tooltip: 'Değişiklikleri Kaydet',
                      onPressed: onSave,
                      color: Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 22,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
