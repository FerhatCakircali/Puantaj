import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Son aktiviteler kartı
class RecentActivitiesCard extends StatelessWidget {
  final DateTime? lastAttendance;
  final DateTime? lastApproved;
  final DateTime? lastPayment;

  const RecentActivitiesCard({
    super.key,
    this.lastAttendance,
    this.lastApproved,
    this.lastPayment,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryColor = Color(0xFF4338CA);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.05),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(w * 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.025),
                decoration: BoxDecoration(
                  color: isDark
                      ? primaryColor.withValues(alpha: 0.2)
                      : primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
                child: Icon(Icons.history, color: primaryColor, size: w * 0.06),
              ),
              SizedBox(width: w * 0.03),
              Text(
                'Son Aktiviteler',
                style: TextStyle(
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: h * 0.02),
          _buildActivityItem(
            context,
            icon: Icons.calendar_today,
            label: 'Son Yevmiye Girişi',
            date: lastAttendance,
            color: Colors.blue,
            isDark: isDark,
          ),
          SizedBox(height: h * 0.012),
          _buildActivityItem(
            context,
            icon: Icons.check_circle,
            label: 'Son Onaylanan Talep',
            date: lastApproved,
            color: Colors.green,
            isDark: isDark,
          ),
          SizedBox(height: h * 0.012),
          _buildActivityItem(
            context,
            icon: Icons.payment,
            label: 'Son Ödeme',
            date: lastPayment,
            color: Colors.orange,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required DateTime? date,
    required Color color,
    required bool isDark,
  }) {
    final w = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    String dateText;
    if (date == null) {
      dateText = 'Henüz yok';
    } else {
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        dateText = 'Bugün';
      } else if (difference.inDays == 1) {
        dateText = 'Dün';
      } else if (difference.inDays < 7) {
        dateText = '${difference.inDays} gün önce';
      } else {
        dateText = DateFormat('dd MMM yyyy', 'tr_TR').format(date);
      }
    }

    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.02),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(w * 0.02),
            ),
            child: Icon(icon, color: color, size: w * 0.05),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: w * 0.037,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            dateText,
            style: TextStyle(
              fontSize: w * 0.035,
              fontWeight: FontWeight.w600,
              color: date != null
                  ? color
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
