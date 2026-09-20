import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/welcome_screen.dart';
import 'dart:async';
import 'dart:math';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const WaddahApp());
}

class WaddahApp extends StatelessWidget {
  const WaddahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'وضّاح',
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFFF6DD),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const IntroScreen(),
    );
  }
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _waveCtrl;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _navTimer = Timer(const Duration(milliseconds: 4000), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, animation, __) => WelcomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.03, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _fadeCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: _fadeCtrl,
      curve: Curves.easeOut,
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: fade,
            child: Image.asset(
              'assets/images/splash_background.png',
              fit: BoxFit.cover,
            ),
          ),

        ],
      ),
    );
  }
}


class SplashOverlayPainter extends CustomPainter {
  final double t;

  SplashOverlayPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = const Color(0xFFBFEFFF).withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final path = Path();
    final baseY = size.height * 0.76;

    path.moveTo(0, baseY);

    for (double x = 0; x <= size.width; x += 14) {
      final y = baseY +
          sin((x / size.width * 2 * pi) + t * 2 * pi) * 10;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, wavePaint);

    final bubblePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final x = size.width * (0.12 + i * 0.1);
      final y = size.height * (0.25 + (i % 3) * 0.12) +
          sin((t * 2 * pi) + i) * 10;

      bubblePaint.color = i.isEven
          ? const Color(0xFFBFEFDD).withOpacity(0.18)
          : const Color(0xFFE2D4FF).withOpacity(0.16);

      canvas.drawCircle(
        Offset(x, y),
        5 + (i % 3) * 2,
        bubblePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SplashOverlayPainter oldDelegate) => true;
}

class LogoWavePainter extends CustomPainter {
  final double t;

  LogoWavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFBFEFDD),
          Color(0xFFB8C9FF),
          Color(0xFFE2D4FF),
        ],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    for (double x = 0; x <= size.width; x += 4) {
      final y = size.height / 2 +
          sin((x / size.width * 4 * pi) + (t * 2 * pi)) * 8;

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LogoWavePainter oldDelegate) => true;
}

