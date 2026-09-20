import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dart:math';

class WelcomeScreen extends StatelessWidget {
  WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/welcome_screen.png',
            fit: BoxFit.cover,
          ),

          const WelcomeBubbles(),

          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 320,
                  height: 78,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFBFEFDD),
                        Color(0xFFB8C9FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.14),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomeBubbles extends StatefulWidget {
  const WelcomeBubbles({super.key});

  @override
  State<WelcomeBubbles> createState() => _WelcomeBubblesState();
}

class _WelcomeBubblesState extends State<WelcomeBubbles>
    with SingleTickerProviderStateMixin {
  late final AnimationController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        return CustomPaint(
          painter: WelcomeBubblePainter(ctrl.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class WelcomeBubblePainter extends CustomPainter {
  final double t;

  WelcomeBubblePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final bubbles = <Map<String, double>>[
      {'x': 0.10, 'baseY': 0.88, 'r': 13},
      {'x': 0.18, 'baseY': 0.78, 'r': 18},
      {'x': 0.25, 'baseY': 0.90, 'r': 10},
      {'x': 0.34, 'baseY': 0.73, 'r': 16},
      {'x': 0.46, 'baseY': 0.84, 'r': 12},
      {'x': 0.55, 'baseY': 0.74, 'r': 20},
      {'x': 0.64, 'baseY': 0.87, 'r': 14},
      {'x': 0.72, 'baseY': 0.79, 'r': 19},
      {'x': 0.81, 'baseY': 0.90, 'r': 11},
      {'x': 0.90, 'baseY': 0.82, 'r': 17},
      {'x': 0.14, 'baseY': 0.36, 'r': 12},
      {'x': 0.82, 'baseY': 0.30, 'r': 15},
      {'x': 0.61, 'baseY': 0.20, 'r': 9},
    ];

    for (int i = 0; i < bubbles.length; i++) {
      final item = bubbles[i];
      final phase = (t + i * 0.09) % 1.0;
      final dx = sin((t * 2 * pi) + i) * 8;
      final x = size.width * item['x']! + dx;
      final y = size.height * (item['baseY']! - phase * 0.28);
      final r = item['r']! * 1.35 + sin((t * 2 * pi) + i * 0.7) * 2.8;

      fill.color = (i.isEven
        ? const Color(0xFF7EC8E3)
        : const Color(0xFFE2D4FF))
    .withOpacity(0.22);

stroke.color = Colors.white.withOpacity(0.55);

      canvas.drawCircle(Offset(x, y), r, fill);
      canvas.drawCircle(Offset(x, y), r, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant WelcomeBubblePainter oldDelegate) => true;
}