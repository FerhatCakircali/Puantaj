import 'package:flutter/material.dart';
import '../basic/shimmer_card.dart';
import '../basic/shimmer_text.dart';
import '../basic/shimmer_circle.dart';

/// Profil için shimmer layout
class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profil başlığı shimmer
          Row(
            children: [
              const ShimmerCircle(radius: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerText(width: 200, height: 24),
                    const SizedBox(height: 4),
                    ShimmerText(width: 150, height: 16),
                    const SizedBox(height: 8),
                    ShimmerCard(width: 60, height: 24),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Profil bilgileri kartı shimmer
          const ShimmerCard(height: 200),
          const SizedBox(height: 16),

          // Güvenlik kartı shimmer
          const ShimmerCard(height: 100),
        ],
      ),
    );
  }
}
