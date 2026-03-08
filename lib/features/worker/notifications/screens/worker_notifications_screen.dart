import 'package:flutter/material.dart';
import '../controllers/notification_controller.dart';
import '../helpers/notification_helper.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_filter_chips.dart';
import '../widgets/notification_stats_cards.dart';
import '../widgets/notification_empty_state.dart';

/// Çalışan bildirimleri ekranı
class WorkerNotificationsScreen extends StatefulWidget {
  const WorkerNotificationsScreen({super.key});

  @override
  State<WorkerNotificationsScreen> createState() =>
      _WorkerNotificationsScreenState();
}

class _WorkerNotificationsScreenState extends State<WorkerNotificationsScreen> {
  late final NotificationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NotificationController(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    _controller.loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    const primaryColor = Color(0xFF4338CA);

    return Scaffold(
      body: _controller.isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                if (_controller.unreadCount > 0) _buildMarkAllButton(w, h),
                if (_controller.notifications.isNotEmpty)
                  NotificationStatsCards(
                    unreadCount: _controller.unreadCount,
                    todayCount: _controller.todayCount,
                    totalCount: _controller.notifications.length,
                  ),
                if (_controller.notifications.isNotEmpty)
                  NotificationFilterChips(
                    selectedReadFilter: _controller.readFilter,
                    selectedTypeFilter: _controller.typeFilter,
                    onReadFilterChanged: _controller.setReadFilter,
                    onTypeFilterChanged: _controller.setTypeFilter,
                  ),
                Expanded(
                  child: _controller.filteredNotifications.isEmpty
                      ? NotificationEmptyState(
                          readFilter: _controller.readFilter,
                          typeFilter: _controller.typeFilter,
                        )
                      : RefreshIndicator(
                          onRefresh: _controller.loadNotifications,
                          color: primaryColor,
                          child: _buildNotificationList(w, h),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildMarkAllButton(double w, double h) {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: w * 0.04, top: h * 0.01),
      child: TextButton.icon(
        onPressed: _controller.markAllAsRead,
        icon: Icon(Icons.done_all, size: w * 0.045),
        label: Text(
          'Tümünü okundu işaretle',
          style: TextStyle(fontSize: w * 0.035),
        ),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF4338CA),
          backgroundColor: const Color(0xFF4338CA).withValues(alpha: 0.1),
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.04,
            vertical: h * 0.01,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList(double w, double h) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.01, w * 0.04, h * 0.12),
      itemCount: _controller.filteredNotifications.length,
      itemExtent: 120.0,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        final notification = _controller.filteredNotifications[index];
        return NotificationCard(
          notification: notification,
          onTap: () => _handleNotificationTap(notification),
        );
      },
    );
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    final id = notification['id'] as int;
    final isRead = notification['is_read'] as bool;
    final notificationType = notification['notification_type'] as String;
    final relatedId = notification['related_id'] as int?;

    if (!isRead) {
      await _controller.markAsRead(id);
    }

    if (mounted) {
      await NotificationHelper.handleNotificationTap(
        context,
        notificationType,
        relatedId,
      );
    }
  }
}
