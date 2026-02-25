import 'package:flutter/material.dart';
import '../services/admin_stats_service.dart';
import 'recent_activities_card.dart';
import 'user_growth_chart.dart';
import 'user_distribution_card.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  int _refreshKey = 0;

  Future<void> _handleRefresh() async {
    // Cache'i temizle
    AdminStatsService().clearStatsCache();

    // Widget'ları yeniden build et
    if (mounted) {
      setState(() {
        _refreshKey++; // Key değiştirerek widget'ları yeniden oluştur
      });
    }

    // Kısa bir gecikme ekle (kullanıcı deneyimi için)
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _handleRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            child: Column(
              key: ValueKey(_refreshKey), // Key ile widget'ları yenile
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Row(
                  children: [
                    const Icon(Icons.dashboard, size: 24),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _refreshIndicatorKey.currentState?.show();
                      },
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Yenile',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Kullanıcı Büyümesi ve Dağılım
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 800;

                    if (isSmallScreen) {
                      return Column(
                        children: [
                          UserGrowthChart(key: ValueKey('growth_$_refreshKey')),
                          const SizedBox(height: 12),
                          UserDistributionCard(
                            key: ValueKey('dist_$_refreshKey'),
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: UserGrowthChart(
                              key: ValueKey('growth_$_refreshKey'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: UserDistributionCard(
                              key: ValueKey('dist_$_refreshKey'),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Son Aktiviteler
                RecentActivitiesCard(key: ValueKey('activities_$_refreshKey')),

                // Alt boşluk ekle
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
