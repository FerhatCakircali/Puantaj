import 'package:flutter/material.dart';

/// Shimmer daire widget'ı
class ShimmerCircle extends StatelessWidget {
  final double radius;

  const ShimmerCircle({super.key, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}
