import 'package:flutter/material.dart';

class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    if (widget.isLoading) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final baseColor = widget.baseColor ?? Colors.grey[300]!;
    final highlightColor = widget.highlightColor ?? Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [0.0, 0.5, 1.0],
              transform: GradientRotation(_animation.value * 3.14159),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

// Shimmer için hazır widget'lar
class ShimmerCard extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ShimmerCard({super.key, this.width, this.height, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? 100,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

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

// Dashboard için shimmer
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

// Kullanıcı listesi için shimmer
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

// Profil için shimmer
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
