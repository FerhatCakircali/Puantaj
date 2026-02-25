import 'package:flutter/material.dart';

/// Hızlı istatistikler kartı (mini kartlar)
class QuickStatsCard extends StatelessWidget {
  final int unreadNotifications;
  final int weeklyDays;
  final int totalDays;

  const QuickStatsCard({
    super.key,
    required this.unreadNotifications,
    required this.weeklyDays,
    required this.totalDays,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          Text(
            'Hızlı Bakış',
            style: TextStyle(
              fontSize: w * 0.045,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: h * 0.02),
          Row(
            children: [
              Expanded(
                child: _buildMiniCard(
                  context,
                  icon: Icons.notifications_active,
                  label: 'Okunmamış',
                  value: unreadNotifications.toString(),
                  color: Colors.red,
                  isDark: isDark,
                ),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: _buildMiniCard(
                  context,
                  icon: Icons.calendar_today,
                  label: 'Bu Hafta',
                  value: '$weeklyDays gün',
                  color: Colors.blue,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          SizedBox(height: h * 0.015),
          _buildMiniCard(
            context,
            icon: Icons.work_history,
            label: 'Toplam Çalışma',
            value: '$totalDays gün',
            color: Colors.green,
            isDark: isDark,
            isWide: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    bool isWide = false,
  }) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: w * 0.0025,
        ),
      ),
      child: isWide
          ? Row(
              children: [
                Icon(icon, color: color, size: w * 0.06),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: w * 0.033,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      SizedBox(height: h * 0.003),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: w * 0.045,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: w * 0.06),
                SizedBox(height: h * 0.01),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: w * 0.033,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: h * 0.003),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: w * 0.045,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
    );
  }
}
