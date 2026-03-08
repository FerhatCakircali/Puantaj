import 'package:flutter/material.dart';

/// Bildirim boş durum widget'ı
///
/// Bildirim olmadığında gösterilir.
class NotificationEmptyState extends StatelessWidget {
  final String selectedFilter;

  const NotificationEmptyState({super.key, required this.selectedFilter});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String emptyMessage = 'Bildiriminiz bulunmuyor';
    IconData emptyIcon = Icons.notifications_none_rounded;

    if (selectedFilter == 'unread') {
      emptyMessage = 'Okunmamış bildiriminiz yok';
      emptyIcon = Icons.mark_email_read_outlined;
    } else if (selectedFilter == 'read') {
      emptyMessage = 'Okunmuş bildiriminiz yok';
      emptyIcon = Icons.drafts_outlined;
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
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.grey.shade700,
            ),
          ),
          SizedBox(height: h * 0.01),
          Text(
            selectedFilter != 'all'
                ? 'Farklı bir filtre deneyin'
                : 'Yeni bildirimler burada görünecek',
            style: TextStyle(
              fontSize: w * 0.035,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
