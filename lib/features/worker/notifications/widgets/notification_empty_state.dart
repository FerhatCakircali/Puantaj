import 'package:flutter/material.dart';
import '../models/notification_filter.dart';

/// Boş bildirim durumu widget'ı
class NotificationEmptyState extends StatelessWidget {
  final NotificationReadFilter readFilter;
  final NotificationTypeFilter typeFilter;

  const NotificationEmptyState({
    super.key,
    required this.readFilter,
    required this.typeFilter,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final theme = Theme.of(context);

    String emptyMessage = 'Henüz bildirim yok';
    IconData emptyIcon = Icons.notifications_none_rounded;

    if (readFilter == NotificationReadFilter.unread) {
      emptyMessage = 'Okunmamış bildiriminiz yok';
      emptyIcon = Icons.mark_email_read_outlined;
    } else if (readFilter == NotificationReadFilter.read) {
      emptyMessage = 'Okunmuş bildiriminiz yok';
      emptyIcon = Icons.drafts_outlined;
    } else if (typeFilter != NotificationTypeFilter.all) {
      emptyMessage = 'Bu tipte bildirim bulunamadı';
      emptyIcon = Icons.filter_list_off;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            emptyIcon,
            size: w * 0.15,
            color: const Color(0xFF4338CA).withValues(alpha: 0.2),
          ),
          SizedBox(height: h * 0.02),
          Text(
            emptyMessage,
            style: TextStyle(
              fontSize: w * 0.045,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: h * 0.01),
          Text(
            readFilter != NotificationReadFilter.all ||
                    typeFilter != NotificationTypeFilter.all
                ? 'Farklı bir filtre deneyin'
                : 'Yeni bildirimler burada görünecek',
            style: TextStyle(
              fontSize: w * 0.035,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
