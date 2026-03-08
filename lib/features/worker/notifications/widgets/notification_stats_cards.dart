import 'package:flutter/material.dart';

/// Bildirim istatistik kartları
class NotificationStatsCards extends StatelessWidget {
  final int unreadCount;
  final int todayCount;
  final int totalCount;

  const NotificationStatsCards({
    super.key,
    required this.unreadCount,
    required this.todayCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, h * 0.01),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              w: w,
              h: h,
              isDark: isDark,
              icon: Icons.mark_email_unread_outlined,
              label: 'Okunmamış',
              value: unreadCount.toString(),
              color: const Color(0xFF4338CA),
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: _StatCard(
              w: w,
              h: h,
              isDark: isDark,
              icon: Icons.today_outlined,
              label: 'Bugün',
              value: todayCount.toString(),
              color: Colors.orange,
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: _StatCard(
              w: w,
              h: h,
              isDark: isDark,
              icon: Icons.notifications_outlined,
              label: 'Toplam',
              value: totalCount.toString(),
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final double w;
  final double h;
  final bool isDark;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.w,
    required this.h,
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
