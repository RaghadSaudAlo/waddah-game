import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'welcome_screen.dart';

/// Short magical intro (waveform + ripples) then transition to [WelcomeScreen].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _main;
  late final AnimationController _ripple;

  @override
  void initState() {
    super.initState();
    _main = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();

    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _main.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (_, _, _) => WelcomeScreen(),
            transitionsBuilder: (_, anim, _, child) {
              final curved = CurvedAnimation(
                parent: anim,
                curve: Curves.easeOutCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
                  child: child,
                ),
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _main.dispose();
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4EF),
      body: AnimatedBuilder(
        animation: Listenable.merge([_main, _ripple]),
        builder: (context, _) {
          final t = CurvedAnimation(
            parent: _main,
            curve: Curves.easeOutCubic,
          ).value;
          final fade = t.clamp(0.0, 1.0);
          final scale = 0.88 + 0.12 * fade;

          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _RipplePainter(phase: _ripple.value),
              ),
              Center(
                child: Opacity(
                  opacity: fade,
                  child: Transform.scale(
                    scale: scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 100,
                          width: MediaQuery.sizeOf(context).width * 0.72,
                          child: CustomPaint(
                            painter: _WaveformPainter(phase: _ripple.value),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'وضّاح',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: AppColors.deepMint.withValues(alpha: 0.85 + 0.15 * fade),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'لعبة النطق العربية',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink.withValues(alpha: 0.55 * fade),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final paint = Paint()
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const bars = 36;
    for (var i = 0; i < bars; i++) {
      final x = (i + 0.5) / bars * size.width;
      final wobble = math.sin(phase * math.pi * 2 + i * 0.45) * 0.5 +
          math.sin(phase * math.pi * 4 + i * 0.22) * 0.35;
      final h = (12 + (size.height * 0.38) * (0.45 + wobble)).clamp(8.0, size.height * 0.48);
      paint.shader = LinearGradient(
        colors: [
          AppColors.mint,
          AppColors.deepMint,
          AppColors.sky,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawLine(Offset(x, mid - h / 2), Offset(x, mid + h / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.42);
    for (var i = 0; i < 3; i++) {
      final p = (phase + i * 0.33) % 1.0;
      final radius = p * size.shortestSide * 0.55;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = AppColors.deepMint.withValues(alpha: (1 - p) * 0.22);
      canvas.drawCircle(c, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      oldDelegate.phase != phase;
}
