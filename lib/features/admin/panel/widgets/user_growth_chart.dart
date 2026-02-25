import 'package:flutter/material.dart';
import '../services/admin_stats_service.dart';
import '../../../../models/admin_stats.dart';

class UserGrowthChart extends StatelessWidget {
  const UserGrowthChart({super.key});

  @override
  Widget build(BuildContext context) {
    final adminStatsService = AdminStatsService();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Kullanıcı Büyümesi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<AdminStats>(
              future: adminStatsService.getStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: Text('Veri yüklenemedi')),
                  );
                }

                final stats = snapshot.data!;
                final maxValue = [
                  stats.todayRegistrations,
                  stats.weeklyRegistrations,
                  stats.monthlyRegistrations,
                ].reduce((a, b) => a > b ? a : b).toDouble();

                return Column(
                  children: [
                    _buildGrowthBar(
                      context,
                      'Bugün',
                      stats.todayRegistrations,
                      maxValue,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildGrowthBar(
                      context,
                      'Bu Hafta',
                      stats.weeklyRegistrations,
                      maxValue,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildGrowthBar(
                      context,
                      'Bu Ay',
                      stats.monthlyRegistrations,
                      maxValue,
                      Colors.orange,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthBar(
    BuildContext context,
    String label,
    int value,
    double maxValue,
    Color color,
  ) {
    final percentage = maxValue > 0 ? (value / maxValue) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
