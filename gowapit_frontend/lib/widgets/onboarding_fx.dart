import 'dart:math' as math;
import 'package:flutter/material.dart';

// ============================================================================
// 1. PARALLAX BACKGROUND
// Multi-layer ambient gradient and abstract shapes that move with page offset
// ============================================================================
class ParallaxBackground extends StatelessWidget {
  final double pageOffset; // e.g. 0.0 to 2.0
  final bool isDarkMode;

  const ParallaxBackground({
    super.key,
    required this.pageOffset,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Theme colors per slide
    final List<Color> slideGradients = isDarkMode
        ? [
            const Color(0xFF1B332A), // Forest Dark
            const Color(0xFF1F3025), // Adventure Dark
            const Color(0xFF162B3D), // Weather Dark
          ]
        : [
            const Color(0xFF9DC3C2), // Light Blue
            const Color(0xFFB3D89C), // Celadon
            const Color(0xFFD0EFB1), // Tea Green
          ];

    final Color bottomBg = isDarkMode ? const Color(0xFF121212) : Colors.white;

    // Calculate interpolated background color based on pageOffset
    final int baseIndex = pageOffset.floor().clamp(0, slideGradients.length - 1);
    final int nextIndex = (baseIndex + 1).clamp(0, slideGradients.length - 1);
    final double fraction = (pageOffset - baseIndex).clamp(0.0, 1.0);

    final Color currentTopColor = Color.lerp(
      slideGradients[baseIndex],
      slideGradients[nextIndex],
      fraction,
    )!;

    final Size screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Base Dynamic Gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  currentTopColor,
                  bottomBg,
                ],
                stops: const [0.0, 0.75],
              ),
            ),
          ),
        ),

        // Parallax Layer 1: Slow Floating Ambient Orb (Left to Right)
        Positioned(
          top: screenSize.height * 0.15,
          left: -80 - (pageOffset * 60),
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: isDarkMode ? 0.08 : 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Parallax Layer 2: Fast Floating Ambient Orb (Right to Left)
        Positioned(
          top: screenSize.height * 0.35,
          right: -100 + (pageOffset * 90),
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF88BDA4).withValues(alpha: isDarkMode ? 0.12 : 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 2. PARTICLE LAYER
// Ambient glowing / floating particles drifting upwards
// ============================================================================
class ParticleLayer extends StatefulWidget {
  final bool isDarkMode;
  const ParticleLayer({super.key, required this.isDarkMode});

  @override
  State<ParticleLayer> createState() => _ParticleLayerState();
}

class _ParticleLayerState extends State<ParticleLayer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    // Generate 18 particles
    for (int i = 0; i < 18; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 4.0 + 2.0,
        speed: _random.nextDouble() * 0.0015 + 0.0008,
        opacity: _random.nextDouble() * 0.4 + 0.2,
      ));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        for (var p in _particles) {
          p.y -= p.speed;
          if (p.y < 0) {
            p.y = 1.0;
            p.x = _random.nextDouble();
          }
        }
        setState(() {});
      })
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ParticlePainter(_particles, widget.isDarkMode),
        size: Size.infinite,
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final bool isDarkMode;

  _ParticlePainter(this.particles, this.isDarkMode);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    for (var p in particles) {
      paint.color = (isDarkMode ? const Color(0xFF88BDA4) : Colors.white)
          .withValues(alpha: p.opacity);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

// ============================================================================
// 3. TAP BURST & INTERACTIVE FACT CARD
// Interactive ripple + burst particles on tap + trivia popup
// ============================================================================
class TapBurst extends StatefulWidget {
  final Widget child;
  final String factText;
  final Color accentColor;

  const TapBurst({
    super.key,
    required this.child,
    required this.factText,
    required this.accentColor,
  });

  @override
  State<TapBurst> createState() => _TapBurstState();
}

class _TapBurstState extends State<TapBurst> with TickerProviderStateMixin {
  late AnimationController _burstController;
  late AnimationController _factCardController;
  Offset _tapPosition = Offset.zero;
  bool _showFactCard = false;
  final math.Random _random = math.Random();
  final List<double> _angles = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 10; i++) {
      _angles.add(_random.nextDouble() * 2 * math.pi);
    }

    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _factCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _burstController.dispose();
    _factCardController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    setState(() {
      _tapPosition = box.globalToLocal(details.globalPosition);
      _showFactCard = true;
    });

    _burstController.forward(from: 0.0);
    _factCardController.forward(from: 0.0);

    // Auto-dismiss fact card after 2.5s
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && _showFactCard) {
        _factCardController.reverse().then((_) {
          if (mounted) setState(() => _showFactCard = false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,

          // Burst Particles Overlay
          AnimatedBuilder(
            animation: _burstController,
            builder: (context, child) {
              if (!_burstController.isAnimating) return const SizedBox.shrink();
              final double progress = _burstController.value;
              return CustomPaint(
                painter: _BurstPainter(
                  center: _tapPosition,
                  angles: _angles,
                  progress: progress,
                  color: widget.accentColor,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Fact Card Popup
          if (_showFactCard)
            Positioned(
              bottom: 12,
              child: AnimatedBuilder(
                animation: _factCardController,
                builder: (context, child) {
                  final double scale = CurvedAnimation(
                    parent: _factCardController,
                    curve: Curves.elasticOut,
                  ).value;
                  return Transform.scale(
                    scale: scale.clamp(0.0, 1.2),
                    child: Opacity(
                      opacity: _factCardController.value.clamp(0.0, 1.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2923).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.accentColor.withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, color: widget.accentColor, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              widget.factText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final Offset center;
  final List<double> angles;
  final double progress;
  final Color color;

  _BurstPainter({
    required this.center,
    required this.angles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0));
    final double radius = progress * 60.0;

    for (var angle in angles) {
      final double x = center.dx + radius * math.cos(angle);
      final double y = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), (1.0 - progress) * 4.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) => true;
}
