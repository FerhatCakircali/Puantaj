import 'package:flutter/material.dart';

/// Devam istatistikleri trend kartı (son 3 ay)
class AttendanceTrendCard extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;

  const AttendanceTrendCard({super.key, required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryColor = Color(0xFF4338CA);

    // En çok çalışılan ayı bul
    int maxDays = 0;
    String bestMonth = '';
    for (var data in monthlyData) {
      final totalDays = (data['full_days'] as int) + (data['half_days'] as int);
      if (totalDays > maxDays) {
        maxDays = totalDays;
        bestMonth = data['month_name'] as String;
      }
    }

    // Trend hesapla (son ay vs önceki ay)
    String trend = 'Sabit';
    IconData trendIcon = Icons.trending_flat;
    Color trendColor = Colors.grey;

    if (monthlyData.length >= 2) {
      final lastMonth =
          (monthlyData.last['full_days'] as int) +
          (monthlyData.last['half_days'] as int);
      final prevMonth =
          (monthlyData[monthlyData.length - 2]['full_days'] as int) +
          (monthlyData[monthlyData.length - 2]['half_days'] as int);

      if (lastMonth > prevMonth) {
        trend = 'Artıyor';
        trendIcon = Icons.trending_up;
        trendColor = Colors.green;
      } else if (lastMonth < prevMonth) {
        trend = 'Azalıyor';
        trendIcon = Icons.trending_down;
        trendColor = Colors.red;
      }
    }

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
                child: Icon(
                  Icons.show_chart,
                  color: primaryColor,
                  size: w * 0.06,
                ),
              ),
              SizedBox(width: w * 0.03),
              Text(
                'Son 3 Ay Trendi',
                style: TextStyle(
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: h * 0.025),
          // Grafik
          _buildChart(context, isDark),
          SizedBox(height: h * 0.025),
          // İstatistikler
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  context,
                  label: 'En Çok Çalışılan',
                  value: bestMonth,
                  icon: Icons.star,
                  color: Colors.amber,
                  isDark: isDark,
                ),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: _buildStatBox(
                  context,
                  label: 'Trend',
                  value: trend,
                  icon: trendIcon,
                  color: trendColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, bool isDark) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    // Maksimum değeri bul (grafik ölçeklendirmesi için)
    int maxValue = 0;
    for (var data in monthlyData) {
      final total = (data['full_days'] as int) + (data['half_days'] as int);
      if (total > maxValue) maxValue = total;
    }

    if (maxValue == 0) maxValue = 1; // Sıfıra bölme hatası önleme

    return SizedBox(
      height: h * 0.18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: monthlyData.map((data) {
          final fullDays = data['full_days'] as int;
          final halfDays = data['half_days'] as int;
          final total = fullDays + halfDays;
          final monthName = data['month_name'] as String;

          // Bar yüksekliği oransal olarak hesapla
          final heightRatio = maxValue > 0 ? (total / maxValue) : 0.0;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.01),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sayı - sabit yükseklik
                  SizedBox(
                    height: h * 0.025,
                    child: Center(
                      child: Text(
                        total.toString(),
                        style: TextStyle(
                          fontSize: w * 0.032,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(height: h * 0.003),
                  // Bar - flexible alan
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: heightRatio < 0.15 ? 0.15 : heightRatio,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF4338CA),
                              const Color(0xFF4338CA).withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(w * 0.02),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: h * 0.005),
                  // Ay adı - sabit yükseklik
                  SizedBox(
                    height: h * 0.02,
                    child: Center(
                      child: Text(
                        monthName,
                        style: TextStyle(
                          fontSize: w * 0.028,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatBox(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
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
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: w * 0.0025,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: w * 0.06),
          SizedBox(height: h * 0.008),
          Text(
            label,
            style: TextStyle(
              fontSize: w * 0.03,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: h * 0.003),
          Text(
            value,
            style: TextStyle(
              fontSize: w * 0.038,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
