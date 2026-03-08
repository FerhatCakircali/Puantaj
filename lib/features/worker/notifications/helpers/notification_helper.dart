import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bildirim yardımcı fonksiyonları
class NotificationHelper {
  /// Bildirim mesajındaki İngilizce terimleri Türkçeye çevirir
  static String translateMessage(String message) {
    return message
        .replaceAll('(fullDay)', '(Tam Gün)')
        .replaceAll('(halfDay)', '(Yarım Gün)')
        .replaceAll('fullDay', 'Tam Gün')
        .replaceAll('halfDay', 'Yarım Gün');
  }

  /// Bildirim tipine göre ikon döndürür
  static IconData getIcon(String type) {
    switch (type) {
      case 'attendance_request':
        return Icons.calendar_today;
      case 'attendance_reminder':
        return Icons.alarm;
      case 'attendance_approved':
        return Icons.check_circle;
      case 'attendance_rejected':
        return Icons.cancel;
      case 'payment_received':
      case 'payment_notification':
        return Icons.payment;
      case 'payment_updated':
        return Icons.edit_notifications;
      case 'payment_deleted':
        return Icons.delete_outline;
      case 'general':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  /// Bildirim tipine göre renk döndürür
  static Color getColor(String type, ThemeData theme) {
    switch (type) {
      case 'attendance_request':
        return Colors.blue;
      case 'attendance_reminder':
        return Colors.orange;
      case 'attendance_approved':
        return Colors.green;
      case 'attendance_rejected':
        return Colors.red;
      case 'payment_received':
      case 'payment_notification':
        return Colors.green;
      case 'payment_updated':
        return Colors.blue;
      case 'payment_deleted':
        return Colors.red;
      case 'general':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.onSurface;
    }
  }

  /// Bildirime tıklandığında yönlendirme yapar
  static Future<void> handleNotificationTap(
    BuildContext context,
    String notificationType,
    int? relatedId,
  ) async {
    switch (notificationType) {
      case 'payment_received':
        await _navigateToPaymentHistory(context);
        break;
      case 'attendance_approved':
      case 'attendance_rejected':
      case 'attendance_reminder':
      case 'payment_updated':
      case 'payment_deleted':
      default:
        break;
    }
  }

  static Future<void> _navigateToPaymentHistory(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('worker_attendance_initial_tab', 1);
      await prefs.setString('worker_notification_type', 'payment_received');
      await prefs.setBool('has_pending_notification', true);

      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('Yönlendirme bilgisi kaydedilemedi: $e');
    }
  }
}
