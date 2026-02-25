import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../screens/constants/colors.dart';

/// Bildirim helper metodları
class NotificationHelpers {
  /// Bildirimleri tarihe göre grupla
  static Map<String, List<Map<String, dynamic>>> groupNotificationsByDate(
    List<Map<String, dynamic>> notifications,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<Map<String, dynamic>>> grouped = {
      'Bugün': [],
      'Dün': [],
      'Geçmiş': [],
    };

    for (final notification in notifications) {
      final createdAt = DateTime.parse(notification['created_at']).toLocal();
      final date = DateTime(createdAt.year, createdAt.month, createdAt.day);

      if (date == today) {
        grouped['Bugün']!.add(notification);
      } else if (date == yesterday) {
        grouped['Dün']!.add(notification);
      } else {
        grouped['Geçmiş']!.add(notification);
      }
    }

    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  /// Zaman formatla
  static String formatTimeWithDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = now.difference(dateTime);

    final timeStr = DateFormat('HH:mm').format(dateTime);

    if (date == today) {
      if (difference.inMinutes < 1) {
        return 'Şimdi';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} dakika önce';
      } else {
        return 'Bugün, $timeStr';
      }
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Dün, $timeStr';
    } else {
      return DateFormat('d MMM, HH:mm', 'tr_TR').format(dateTime);
    }
  }

  /// Bildirim tipi için ikon
  static IconData getNotificationIcon(String type) {
    switch (type) {
      case 'attendance_request':
        return Icons.calendar_today_outlined;
      case 'attendance_reminder':
        return Icons.alarm_outlined;
      case 'attendance_approved':
        return Icons.check_circle_outline;
      case 'attendance_rejected':
        return Icons.cancel_outlined;
      case 'payment':
        return Icons.payments_outlined;
      case 'general':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  /// Bildirim tipi için renk
  static Color getNotificationColor(String type) {
    switch (type) {
      case 'attendance_request':
        return primaryIndigo;
      case 'attendance_reminder':
        return Colors.orange;
      case 'attendance_approved':
        return Colors.green;
      case 'attendance_rejected':
        return Colors.red;
      case 'payment':
        return fullDayColor;
      case 'general':
        return primaryIndigo;
      default:
        return primaryIndigo;
    }
  }
}
