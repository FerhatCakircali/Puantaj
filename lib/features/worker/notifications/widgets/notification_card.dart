import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../helpers/notification_helper.dart';

/// Bildirim kartı widget'ı
class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;

    final title = notification['title'] as String;
    final rawMessage = notification['message'] as String;
    final message = NotificationHelper.translateMessage(rawMessage);
    final isRead = notification['is_read'] as bool;
    final createdAt = DateTime.parse(notification['created_at']).toLocal();
    final notificationType = notification['notification_type'] as String;

    final icon = NotificationHelper.getIcon(notificationType);
    final color = NotificationHelper.getColor(notificationType, theme);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: h * 0.015),
        decoration: BoxDecoration(
          color: isRead
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : const Color(0xFFF9FAFB))
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: !isRead
              ? Border(
                  left: BorderSide(color: const Color(0xFF4338CA), width: 4),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: w * 0.04,
                          fontWeight: isRead
                              ? FontWeight.w600
                              : FontWeight.w800,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: isRead ? 0.7 : 1.0,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: h * 0.003),
                    Flexible(
                      child: Text(
                        message,
                        style: TextStyle(
                          fontSize: w * 0.035,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: isRead ? 0.5 : 0.6,
                          ),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: h * 0.004),
                    Text(
                      DateFormat(
                        'dd MMM yyyy, HH:mm',
                        'tr_TR',
                      ).format(createdAt),
                      style: TextStyle(
                        fontSize: w * 0.03,
                        fontWeight: FontWeight.w400,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
