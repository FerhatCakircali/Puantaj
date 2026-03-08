import 'package:flutter/material.dart';

/// Shimmer metin widget'ı
class ShimmerText extends StatelessWidget {
  final double? width;
  final double height;

  const ShimmerText({super.key, this.width, this.height = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
