import 'package:flutter/material.dart';
import '../basic/shimmer_card.dart';
import '../basic/shimmer_text.dart';
import '../basic/shimmer_circle.dart';

/// Kullanıcı listesi için shimmer layout
class UserListShimmer extends StatelessWidget {
  const UserListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Arama alanı shimmer
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const ShimmerCard(height: 56),
              const SizedBox(height: 12),
              Row(
                children: [
                  ShimmerCard(width: 100, height: 40),
                  const Spacer(),
                  ShimmerCard(width: 80, height: 32),
                ],
              ),
            ],
          ),
        ),

        // Kullanıcı kartları shimmer
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 6,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const ShimmerCircle(radius: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerText(width: 150, height: 16),
                            const SizedBox(height: 4),
                            ShimmerText(width: 100, height: 14),
                            const SizedBox(height: 2),
                            ShimmerText(width: 80, height: 12),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ShimmerCard(width: 60, height: 20),
                                const SizedBox(width: 6),
                                ShimmerCard(width: 40, height: 20),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Row(
                            children: [
                              ShimmerCircle(radius: 16),
                              const SizedBox(width: 8),
                              ShimmerCircle(radius: 16),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ShimmerText(width: 12, height: 12),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
