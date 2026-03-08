import 'package:flutter/material.dart';
import '../index.dart';
import 'widgets/notification_stats_cards.dart';
import 'widgets/notification_filter_chips.dart';
import 'widgets/notification_empty_state.dart';
import 'widgets/notification_timeline_list.dart';

/// Kullanıcı bildirimleri ekranı
///
/// Bildirimleri timeline formatında gösterir ve filtreleme imkanı sunar.
class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({super.key});

  @override
  State<UserNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen>
    with NotificationLogicMixin {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == 'unread') {
      return notifications.where((n) => n['is_read'] == false).toList();
    } else if (_selectedFilter == 'read') {
      return notifications.where((n) => n['is_read'] == true).toList();
    }
    return notifications;
  }

  bool get _hasUnreadNotifications {
    return notifications.any((n) => n['is_read'] == false);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    const primaryColor = Color(0xFF4338CA);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                if (_hasUnreadNotifications) _buildMarkAllButton(w, h),
                if (notifications.isNotEmpty)
                  NotificationStatsCards(notifications: notifications),
                if (notifications.isNotEmpty)
                  NotificationFilterChips(
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (filter) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                Expanded(
                  child: _filteredNotifications.isEmpty
                      ? NotificationEmptyState(selectedFilter: _selectedFilter)
                      : RefreshIndicator(
                          onRefresh: loadNotifications,
                          color: primaryColor,
                          child: NotificationTimelineList(
                            notifications: _filteredNotifications,
                            onMarkAsRead: markAsRead,
                            getRequestStatus: getRequestStatus,
                            onApprove: handleApproveRequest,
                            onReject: handleRejectRequest,
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildMarkAllButton(double w, double h) {
    const primaryColor = Color(0xFF4338CA);

    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: w * 0.04, top: h * 0.01),
      child: TextButton.icon(
        onPressed: markAllAsRead,
        icon: Icon(Icons.done_all, size: w * 0.045),
        label: Text(
          'Tümünü okundu işaretle',
          style: TextStyle(fontSize: w * 0.035),
        ),
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          backgroundColor: primaryColor.withValues(alpha: 0.1),
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.04,
            vertical: h * 0.01,
          ),
        ),
      ),
    );
  }
}
