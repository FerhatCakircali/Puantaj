import 'package:flutter/material.dart';
import '../basic/shimmer_card.dart';

/// Dashboard için shimmer layout
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // İstatistik kartları shimmer - responsive layout
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;

            if (isSmallScreen) {
              // Küçük ekranlar için 2x2 grid
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: ShimmerCard(height: 80)),
                      const SizedBox(width: 12),
                      Expanded(child: ShimmerCard(height: 80)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: ShimmerCard(height: 80)),
                      const SizedBox(width: 12),
                      Expanded(child: ShimmerCard(height: 80)),
                    ],
                  ),
                ],
              );
            } else {
              // Büyük ekranlar için 4x1 grid
              return Row(
                children: [
                  Expanded(child: ShimmerCard(height: 80)),
                  const SizedBox(width: 12),
                  Expanded(child: ShimmerCard(height: 80)),
                  const SizedBox(width: 12),
                  Expanded(child: ShimmerCard(height: 80)),
                  const SizedBox(width: 12),
                  Expanded(child: ShimmerCard(height: 80)),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 16),

        // Kayıt istatistikleri shimmer
        const ShimmerCard(height: 120),
        const SizedBox(height: 12),

        // Sistem durumu shimmer
        const ShimmerCard(height: 100),
        const SizedBox(height: 12),

        // Hızlı erişim shimmer
        const ShimmerCard(height: 80),
      ],
    );
  }
}
