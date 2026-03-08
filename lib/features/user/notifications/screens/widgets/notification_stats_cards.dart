import 'package:flutter/material.dart';

/// Bildirim istatistik kartları widget'ı
///
/// Okunmamış, bugün ve toplam bildirim sayılarını gösterir.
class NotificationStatsCards extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;

  const NotificationStatsCards({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
}
