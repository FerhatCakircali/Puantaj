import 'package:flutter/material.dart';
import '../../index.dart';
import 'notification_section_header.dart';

/// Bildirim timeline listesi widget'ı
///
/// Bildirimleri tarih gruplarına göre gösterir.
class NotificationTimelineList extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final Function(int) onMarkAsRead;
  final Future<String?> Function(int) getRequestStatus;
  final Function(int, int) onApprove;
  final Function(int, int) onReject;

  const NotificationTimelineList({
    super.key,
    required this.notifications,
    required this.onMarkAsRead,
    required this.getRequestStatus,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final groupedNotifications = NotificationHelpers.groupNotificationsByDate(
      notifications,
    );

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.01, w * 0.04, h * 0.12),
      itemCount: groupedNotifications.length * 2,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        if (index.isEven) {
          final sectionIndex = index ~/ 2;
          final sectionKey = groupedNotifications.keys.elementAt(sectionIndex);
          return NotificationSectionHeader(title: sectionKey);
        } else {
          final sectionIndex = index ~/ 2;
          final sectionKey = groupedNotifications.keys.elementAt(sectionIndex);
          final sectionNotifications = groupedNotifications[sectionKey]!;
          return Column(
            children: sectionNotifications
                .map(
                  (n) => NotificationTile(
                    notification: n,
                    isDark: isDark,
                    screenWidth: w,
                    screenHeight: h,
                    onMarkAsRead: () => onMarkAsRead(n['id'] as int),
                    getRequestStatus: getRequestStatus,
                    onApprove: onApprove,
                    onReject: onReject,
                  ),
                )
                .toList(),
          );
        }
      },
    );
  }
}
