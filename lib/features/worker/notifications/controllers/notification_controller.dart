import 'package:flutter/material.dart';
import '../../../../data/services/local_storage_service.dart';
import '../../services/worker_notification_service.dart';
import '../models/notification_filter.dart';

/// Bildirim ekranının state ve business logic'ini yöneten controller
class NotificationController {
  final _localStorage = LocalStorageService.instance;
  final _notificationService = WorkerNotificationService();

  bool isLoading = true;
  int? workerId;
  List<Map<String, dynamic>> notifications = [];
  NotificationReadFilter readFilter = NotificationReadFilter.all;
  NotificationTypeFilter typeFilter = NotificationTypeFilter.all;

  final void Function() onStateChanged;

  NotificationController({required this.onStateChanged});

  List<Map<String, dynamic>> get filteredNotifications {
    var filtered = notifications;

    if (readFilter == NotificationReadFilter.unread) {
      filtered = filtered.where((n) => n['is_read'] == false).toList();
    } else if (readFilter == NotificationReadFilter.read) {
      filtered = filtered.where((n) => n['is_read'] == true).toList();
    }

    if (typeFilter == NotificationTypeFilter.attendance) {
      filtered = filtered
          .where(
            (n) => (n['notification_type'] as String).startsWith('attendance'),
          )
          .toList();
    } else if (typeFilter == NotificationTypeFilter.payment) {
      filtered = filtered
          .where(
            (n) => (n['notification_type'] as String).startsWith('payment'),
          )
          .toList();
    }

    return filtered;
  }

  int get unreadCount =>
      notifications.where((n) => n['is_read'] == false).length;

  int get todayCount {
    final today = DateTime.now();
    return notifications.where((n) {
      final createdAt = DateTime.parse(n['created_at']).toLocal();
      return createdAt.year == today.year &&
          createdAt.month == today.month &&
          createdAt.day == today.day;
    }).length;
  }

  Future<void> loadNotifications() async {
    isLoading = true;
    onStateChanged();

    try {
      final session = await _localStorage.getWorkerSession();
      if (session == null) return;

      workerId = int.parse(session['workerId']!);

      final loadedNotifications = await _notificationService
          .getAllNotifications(workerId!);

      notifications = loadedNotifications;
      isLoading = false;
      onStateChanged();
    } catch (e) {
      debugPrint('Bildirim yükleme hatası: $e');
      isLoading = false;
      onStateChanged();
    }
  }

  Future<void> markAsRead(int notificationId) async {
    await _notificationService.markAsRead(notificationId);
    await loadNotifications();
  }

  Future<void> markAllAsRead() async {
    if (workerId == null) return;
    await _notificationService.markAllAsRead(workerId!);
    await loadNotifications();
  }

  void setReadFilter(NotificationReadFilter filter) {
    readFilter = filter;
    onStateChanged();
  }

  void setTypeFilter(NotificationTypeFilter filter) {
    typeFilter = filter;
    onStateChanged();
  }
}
