import 'package:flutter/material.dart';
import '../index.dart';

/// Modern Timeline Bildirimler Ekranı - Enhanced
class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({super.key});

  @override
  State<UserNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen>
    with NotificationLogicMixin {
  String _selectedFilter = 'all'; // all, unread, read

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  List<Map<String, dynamic>> get filteredNotifications {
    var filtered = notifications;

    // Okunma durumuna göre filtrele
    if (_selectedFilter == 'unread') {
      filtered = filtered.where((n) => n['is_read'] == false).toList();
    } else if (_selectedFilter == 'read') {
      filtered = filtered.where((n) => n['is_read'] == true).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const primaryColor = Color(0xFF4338CA);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 0, // AppBar'ı gizle
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                // Tümünü okundu işaretle butonu
                if (notifications.any((n) => n['is_read'] == false))
                  Container(
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
                  ),

                // İstatistik kartları
                if (notifications.isNotEmpty) _buildStatsCards(w, h, isDark),

                // Filtre butonları
                if (notifications.isNotEmpty) _buildFilterChips(w, h, isDark),

                // Bildirim listesi
                Expanded(
                  child: filteredNotifications.isEmpty
                      ? _buildEmptyState(w, h, isDark)
                      : RefreshIndicator(
                          onRefresh: loadNotifications,
                          color: primaryColor,
                          child: _buildTimelineList(w, h, isDark),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsCards(double w, double h, bool isDark) {
    final unreadCount = notifications
        .where((n) => n['is_read'] == false)
        .length;
    final todayCount = notifications.where((n) {
      final createdAt = DateTime.parse(n['created_at']).toLocal();
      final today = DateTime.now();
      return createdAt.year == today.year &&
          createdAt.month == today.month &&
          createdAt.day == today.day;
    }).length;

    return Container(
      padding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, h * 0.01),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              w,
              h,
              isDark,
              icon: Icons.mark_email_unread_outlined,
              label: 'Okunmamış',
              value: unreadCount.toString(),
              color: const Color(0xFF4338CA),
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: _buildStatCard(
              w,
              h,
              isDark,
              icon: Icons.today_outlined,
              label: 'Bugün',
              value: todayCount.toString(),
              color: Colors.orange,
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: _buildStatCard(
              w,
              h,
              isDark,
              icon: Icons.notifications_outlined,
              label: 'Toplam',
              value: notifications.length.toString(),
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    double w,
    double h,
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: h * 0.008, horizontal: w * 0.02),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: w * 0.05),
          SizedBox(height: h * 0.003),
          Text(
            value,
            style: TextStyle(
              fontSize: w * 0.045,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: w * 0.026,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(double w, double h, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(left: w * 0.04, top: h * 0.01, bottom: h * 0.01),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterChip(
                w,
                h,
                isDark,
                label: 'Tümü',
                isSelected: _selectedFilter == 'all',
                onTap: () => setState(() => _selectedFilter = 'all'),
              ),
              SizedBox(width: w * 0.02),
              _buildFilterChip(
                w,
                h,
                isDark,
                label: 'Okunmamış',
                isSelected: _selectedFilter == 'unread',
                onTap: () => setState(() => _selectedFilter = 'unread'),
              ),
              SizedBox(width: w * 0.02),
              _buildFilterChip(
                w,
                h,
                isDark,
                label: 'Okunmuş',
                isSelected: _selectedFilter == 'read',
                onTap: () => setState(() => _selectedFilter = 'read'),
              ),
              SizedBox(width: w * 0.04), // Sağ padding için
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    double w,
    double h,
    bool isDark, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const primaryColor = Color(0xFF4338CA);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(w * 0.05),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.01),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(w * 0.05),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: w * 0.035,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double w, double h, bool isDark) {
    String emptyMessage = 'Bildiriminiz bulunmuyor';
    IconData emptyIcon = Icons.notifications_none_rounded;

    if (_selectedFilter == 'unread') {
      emptyMessage = 'Okunmamış bildiriminiz yok';
      emptyIcon = Icons.mark_email_read_outlined;
    } else if (_selectedFilter == 'read') {
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
            _selectedFilter != 'all'
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

  Widget _buildTimelineList(double w, double h, bool isDark) {
    final groupedNotifications = NotificationHelpers.groupNotificationsByDate(
      filteredNotifications,
    );

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.01, w * 0.04, h * 0.12),
      itemCount: groupedNotifications.length * 2,
      itemBuilder: (context, index) {
        if (index.isEven) {
          final sectionIndex = index ~/ 2;
          final sectionKey = groupedNotifications.keys.elementAt(sectionIndex);
          return _buildSectionHeader(sectionKey, w, h, isDark);
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
                    onMarkAsRead: () => markAsRead(n['id'] as int),
                    getRequestStatus: getRequestStatus,
                    onApprove: handleApproveRequest,
                    onReject: handleRejectRequest,
                  ),
                )
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildSectionHeader(String title, double w, double h, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(top: h * 0.015, bottom: h * 0.01),
      child: Row(
        children: [
          Container(
            width: w * 0.012,
            height: w * 0.012,
            decoration: BoxDecoration(
              color: const Color(0xFF4338CA).withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: w * 0.025),
          Text(
            title,
            style: TextStyle(
              fontSize: w * 0.038,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.shade300,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
