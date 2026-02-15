import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui'; // ImageFilter için

/// Tema değişimi için gelişmiş sanatsal animasyon widget'ı
class ThemeToggleAnimation extends StatefulWidget {
  final bool goingToDark;
  final VoidCallback onAnimationComplete;
  final Offset? center;

  /// Tema değişimi için animasyon gösterir
  ///
  /// [goingToDark] Koyu temaya geçiş yapılıyorsa true, açık temaya geçiş yapılıyorsa false
  /// [onAnimationComplete] Animasyon tamamlandığında çağrılacak fonksiyon
  /// [center] Animasyonun merkez noktası
  const ThemeToggleAnimation({
    Key? key,
    required this.goingToDark,
    required this.onAnimationComplete,
    this.center,
  }) : super(key: key);

  /// Tema değişimi animasyonunu dialog olarak gösterir
  static Future<void> show(
    BuildContext context, {
    required bool goingToDark,
    required VoidCallback onAnimationComplete,
    Offset? center,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      barrierLabel: 'Tema Değişimi',
      transitionDuration: const Duration(milliseconds: 1500),
      pageBuilder: (context, _, __) => ThemeToggleAnimation(
        goingToDark: goingToDark,
        onAnimationComplete: onAnimationComplete,
        center: center,
      ),
    );
  }

  @override
  State<ThemeToggleAnimation> createState() => _ThemeToggleAnimationState();
}

class _ThemeToggleAnimationState extends State<ThemeToggleAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;
  late final Animation<double> _iconScaleAnim;
  late final Animation<double> _iconRotateAnim;
  late final Animation<double> _glowAnim;

  // Yıldız/parçacık animasyonları için değişkenler
  late final List<Animation<Offset>> _starPosAnims;
  late final List<Animation<double>> _starOpacityAnims;
  late final List<double> _starSizes;
  final int _numberOfStars = 25; // Daha fazla yıldız
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Animasyon süresi (1500ms)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Ölçeklendirme animasyonu
    _scaleAnim = Tween<double>(
      begin: 0.05,
      end: 10.0, // Çok daha büyük bir maksimum ölçek
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    // Saydamlık animasyonu
    _opacityAnim = Tween<double>(begin: 0.9, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // İkon ölçeklendirme animasyonu
    _iconScaleAnim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    // İkon dönme animasyonu
    _iconRotateAnim =
        Tween<double>(
          begin: 0.0,
          end: widget.goingToDark ? 1.0 : -1.0, // Tam tur dönme
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuint),
        );

    // Parıltı animasyonu
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    // Yıldız animasyonlarını oluştur
    _starPosAnims = [];
    _starOpacityAnims = [];
    _starSizes = [];

    for (int i = 0; i < _numberOfStars; i++) {
      // Rastgele başlangıç ve bitiş pozisyonları
      final double startAngle = _random.nextDouble() * 2 * math.pi;
      final double startRadius = 50 + _random.nextDouble() * 30;
      final startOffset = Offset(
        startRadius * math.cos(startAngle),
        startRadius * math.sin(startAngle),
      );

      final double endAngle = _random.nextDouble() * 2 * math.pi;
      final double endRadius = 120 + _random.nextDouble() * 100;
      final endOffset = Offset(
        endRadius * math.cos(endAngle),
        endRadius * math.sin(endAngle),
      );

      // Yıldız hareket animasyonu
      _starPosAnims.add(
        Tween<Offset>(begin: startOffset, end: endOffset).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              _random.nextDouble() * 0.3, // Rastgele başlama zamanı
              0.8 + _random.nextDouble() * 0.2, // Rastgele bitiş zamanı
              curve: Curves.easeOutSine, // Akışkan hareket
            ),
          ),
        ),
      );

      // Yıldız opaklık animasyonu (belirme ve sönme)
      _starOpacityAnims.add(
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            weight: 0.3,
          ), // Belirme
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 0.0),
            weight: 0.7,
          ), // Sönme
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              _random.nextDouble() * 0.3, // Rastgele başlama zamanı
              0.8 + _random.nextDouble() * 0.2, // Rastgele bitiş zamanı
              curve: Curves.easeOut, // Sönme eğrisi
            ),
          ),
        ),
      );

      // Yıldız boyutları
      _starSizes.add(2.0 + _random.nextDouble() * 6.0); // Rastgele boyut
    }

    // Animasyonu başlat
    _controller.forward();

    // Animasyon tamamlandığında callback'i çağır
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Animasyon bittiğinde callback'i çağır
        widget.onAnimationComplete();

        // Dialog'u kapat
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final animationCenter =
        widget.center ?? Offset(size.width / 2, size.height / 2);

    // Tema moduna göre renkler
    final bool isDark = widget.goingToDark;

    // Gece/gündüz gradyanları
    final gradient = isDark
        ? LinearGradient(
            colors: [
              Colors.indigo.shade300.withOpacity(0.9),
              Colors.deepPurple.shade700.withOpacity(0.8),
              Colors.black.withOpacity(0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              Colors.orange.shade300.withOpacity(0.9),
              Colors.amber.shade500.withOpacity(0.8),
              Colors.white.withOpacity(0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    // İkon rengi ve tipi
    final iconColor = isDark ? Colors.blueGrey.shade700 : Colors.amber.shade600;
    final icon = isDark ? Icons.dark_mode : Icons.light_mode;

    // Parıltı rengi
    final glowColor = isDark ? Colors.blue.shade200 : Colors.orange.shade300;

    return Stack(
      children: [
        // Arkaplan blur efekti
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Animasyon tamamlandığında blur da kaybolsun
            if (_controller.value == 1.0) return const SizedBox.shrink();

            return BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _opacityAnim.value * 15,
                sigmaY: _opacityAnim.value * 15,
              ),
              child: Container(color: Colors.transparent),
            );
          },
        ),

        // Ana genişleyen daire efekti
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Positioned(
              left: animationCenter.dx - (size.width * _scaleAnim.value) / 2,
              top: animationCenter.dy - (size.width * _scaleAnim.value) / 2,
              child: Opacity(
                opacity: _opacityAnim.value,
                child: Container(
                  width: size.width * _scaleAnim.value,
                  height: size.width * _scaleAnim.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: gradient,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.blue : Colors.orange)
                            .withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Yıldız/parçacık efektleri
        ...List.generate(_numberOfStars, (i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Animasyon tamamlandıysa veya opaklık 0 ise gizle
              if (_controller.value >= 1.0 ||
                  _starOpacityAnims[i].value <= 0.01) {
                return const SizedBox.shrink();
              }

              // Yıldızın türü: 0 - daire, 1 - yıldız, 2 - kare
              final starType = i % 3;
              final starColor = i % 4 == 0
                  ? (isDark ? Colors.purple.shade200 : Colors.yellow.shade200)
                  : i % 4 == 1
                  ? (isDark ? Colors.blue.shade300 : Colors.orange.shade300)
                  : i % 4 == 2
                  ? Colors.white
                  : (isDark ? Colors.indigo.shade300 : Colors.amber.shade300);

              return Positioned(
                left:
                    animationCenter.dx +
                    _starPosAnims[i].value.dx -
                    (_starSizes[i] / 2),
                top:
                    animationCenter.dy +
                    _starPosAnims[i].value.dy -
                    (_starSizes[i] / 2),
                child: Opacity(
                  opacity: _starOpacityAnims[i].value,
                  child: starType == 0
                      // Daire şeklinde parçacık
                      ? Container(
                          width: _starSizes[i] + (_glowAnim.value * 3),
                          height: _starSizes[i] + (_glowAnim.value * 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: starColor,
                            boxShadow: [
                              BoxShadow(
                                color: starColor.withOpacity(
                                  _starOpacityAnims[i].value * 0.8,
                                ),
                                blurRadius: _starSizes[i] * 2,
                                spreadRadius: _starSizes[i] * 0.5,
                              ),
                            ],
                          ),
                        )
                      : starType == 1
                      // Yıldız şeklinde parçacık
                      ? Transform.rotate(
                          angle:
                              i * math.pi / 6 + (_controller.value * math.pi),
                          child: CustomPaint(
                            size: Size(_starSizes[i] * 2, _starSizes[i] * 2),
                            painter: StarPainter(
                              color: starColor,
                              points: 5,
                              innerRadiusFactor: 0.4,
                            ),
                          ),
                        )
                      // Kare şeklinde parçacık
                      : Transform.rotate(
                          angle:
                              i * math.pi / 8 +
                              (_controller.value * math.pi * 2),
                          child: Container(
                            width: _starSizes[i] * 1.5,
                            height: _starSizes[i] * 1.5,
                            decoration: BoxDecoration(
                              color: starColor,
                              borderRadius: BorderRadius.circular(
                                _starSizes[i] * 0.3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: starColor.withOpacity(
                                    _starOpacityAnims[i].value * 0.7,
                                  ),
                                  blurRadius: _starSizes[i],
                                  spreadRadius: _starSizes[i] * 0.3,
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              );
            },
          );
        }),

        // Ana ikon efekti
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Parıltı boyutu ve bulanıklığı animasyon değerine bağlı
            final double glowRadius = _glowAnim.value * 40;
            final double spreadRadius = _glowAnim.value * 10;

            return Positioned(
              left: animationCenter.dx - 40,
              top: animationCenter.dy - 40,
              child: Transform.rotate(
                angle: _iconRotateAnim.value * 2 * math.pi, // Tam tur dönme
                child: Transform.scale(
                  scale: _iconScaleAnim.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isDark
                            ? [Colors.grey.shade300, Colors.blueGrey.shade600]
                            : [Colors.yellow.shade200, Colors.amber.shade600],
                        stops: const [0.3, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withOpacity(_glowAnim.value * 0.8),
                          blurRadius: glowRadius,
                          spreadRadius: spreadRadius,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(icon, size: 48, color: Colors.white),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // İkincil halka efekti
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final ringProgress = math.min(1.0, _controller.value * 1.5);
            if (ringProgress <= 0) {
              return const SizedBox.shrink();
            }

            // Daha büyük ve daha ince halka
            return Positioned(
              left: animationCenter.dx - 80 * ringProgress,
              top: animationCenter.dy - 80 * ringProgress,
              child: Opacity(
                opacity: (1 - ringProgress) * 0.6,
                child: Container(
                  width: 160 * ringProgress,
                  height: 160 * ringProgress,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.goingToDark
                          ? Colors.blue.shade200.withOpacity(0.8)
                          : Colors.orange.shade300.withOpacity(0.8),
                      width: 2 * (1 - ringProgress),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (widget.goingToDark
                                    ? Colors.blue.shade200
                                    : Colors.orange.shade300)
                                .withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Yıldız çizici
class StarPainter extends CustomPainter {
  final Color color;
  final int points;
  final double innerRadiusFactor;

  StarPainter({
    required this.color,
    this.points = 5,
    this.innerRadiusFactor = 0.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * innerRadiusFactor;
    final path = Path();

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * math.pi) / points - math.pi / 2;

      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    canvas.drawPath(path, paint);

    // Yıldız parıltısı
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
