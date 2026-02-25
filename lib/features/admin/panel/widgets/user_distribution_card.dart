import 'package:flutter/material.dart';
import '../services/admin_stats_service.dart';
import '../../../../models/admin_stats.dart';

class UserDistributionCard extends StatelessWidget {
  const UserDistributionCard({super.key});

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
                  Icons.pie_chart,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Kullanıcı Dağılımı',
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
                final total = stats.totalUsers;

                return Column(
                  children: [
                    _buildDistributionItem(
                      context,
                      'Aktif Kullanıcılar',
                      stats.activeUsers,
                      total,
                      Colors.green,
                      Icons.check_circle,
                    ),
                    const SizedBox(height: 12),
                    _buildDistributionItem(
                      context,
                      'Bloklu Kullanıcılar',
                      stats.blockedUsers,
                      total,
                      Colors.red,
                      Icons.block,
                    ),
                    const SizedBox(height: 12),
                    _buildDistributionItem(
                      context,
                      'Admin Kullanıcılar',
                      stats.adminUsers,
                      total,
                      Colors.orange,
                      Icons.admin_panel_settings,
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

  Widget _buildDistributionItem(
    BuildContext context,
    String label,
    int value,
    int total,
    Color color,
    IconData icon,
  ) {
    final percentage = total > 0
        ? ((value / total) * 100).toStringAsFixed(1)
        : '0.0';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '($percentage%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
