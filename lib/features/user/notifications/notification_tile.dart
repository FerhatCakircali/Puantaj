import 'package:flutter/material.dart';
import 'notification_actions.dart';
import 'notification_helpers.dart';

/// Bildirim kartı widget'ı
class NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final bool isDark;
  final double screenWidth;
  final double screenHeight;
  final VoidCallback onMarkAsRead;
  final Future<String?> Function(int) getRequestStatus;
  final void Function(int, int) onApprove;
  final void Function(int, int) onReject;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.isDark,
    required this.screenWidth,
    required this.screenHeight,
    required this.onMarkAsRead,
    required this.getRequestStatus,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final w = screenWidth;
    final h = screenHeight;
    final id = notification['id'] as int;
    final title = notification['title'] as String;
    var message = notification['message'] as String;

    // fullDay ve halfDay'i Türkçe'ye çevir
    message = message
        .replaceAll('(fullDay)', '(Tam Gün)')
        .replaceAll('(halfDay)', '(Yarım Gün)')
        .replaceAll('fullDay', 'Tam Gün')
        .replaceAll('halfDay', 'Yarım Gün');

    final isRead = notification['is_read'] as bool;
    final createdAt = DateTime.parse(notification['created_at']).toLocal();
    final notificationType = notification['notification_type'] as String?;
    final relatedId = notification['related_id'] as int?;

    final icon = NotificationHelpers.getNotificationIcon(
      notificationType ?? 'general',
    );
    final color = NotificationHelpers.getNotificationColor(
      notificationType ?? 'general',
    );
    final isAttendanceRequest = notificationType == 'attendance_request';

    return Dismissible(
      key: Key('notification_$id'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: w * 0.05),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: Colors.red, size: w * 0.06),
      ),
      confirmDismiss: (direction) async {
        onMarkAsRead();
        return true;
      },
      child: Column(
        children: [
          InkWell(
            onTap: isRead ? null : onMarkAsRead,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: EdgeInsets.only(bottom: h * 0.015),
              decoration: BoxDecoration(
                color: isRead
                    ? (isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : const Color(0xFFF9FAFB))
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: !isRead
                    ? Border(
                        left: BorderSide(
                          color: const Color(0xFF4338CA),
                          width: 4,
                        ),
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(w * 0.04),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: isRead ? 0.5 : 1.0,
                      child: Container(
                        width: w * 0.11,
                        height: w * 0.11,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: w * 0.055),
                      ),
                    ),
                    SizedBox(width: w * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: w * 0.04,
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              color:
                                  (isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B))
                                      .withValues(alpha: isRead ? 0.7 : 1.0),
                            ),
                          ),
                          SizedBox(height: h * 0.004),
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: w * 0.035,
                              fontWeight: FontWeight.w500,
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: isRead ? 0.5 : 0.6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: h * 0.006),
                          Text(
                            NotificationHelpers.formatTimeWithDate(createdAt),
                            style: TextStyle(
                              fontSize: w * 0.03,
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade500,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isAttendanceRequest && relatedId != null)
            FutureBuilder<String?>(
              future: getRequestStatus(relatedId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: h * 0.01),
                    child: Center(
                      child: SizedBox(
                        height: w * 0.04,
                        width: w * 0.04,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF4338CA),
                        ),
                      ),
                    ),
                  );
                }

                final requestStatus = snapshot.data;

                return NotificationActions(
                  notificationId: id,
                  requestId: relatedId,
                  requestStatus: requestStatus,
                  onApprove: () => onApprove(id, relatedId),
                  onReject: () => onReject(id, relatedId),
                );
              },
            ),
        ],
      ),
    );
  }
}
