import 'package:flutter/material.dart';
import 'home_screen.dart';

class CorrectScreen extends StatelessWidget {
  final Widget? nextScreen;
  final String characterImage;

  const CorrectScreen({
    super.key,
    this.nextScreen,
    required this.characterImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/correct_screen.png',
            fit: BoxFit.cover,
          ),

          Positioned(
            left: 250,
            bottom: 110,
            child: Image.asset(
              characterImage,
              width: 320,
              fit: BoxFit.contain,
            ),
          ),

          Positioned(
            left: 520,
            bottom: 430,
            child: SizedBox(
              width: 430,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3C4),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Text(
                      'أحسنت 🎉\nنطقت الكلمة بشكل صحيح!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D2D2D),
                        height: 1.5,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -22,
                    left: 165,
                    child: CustomPaint(
                      size: const Size(54, 30),
                      painter: BubbleTailPainter(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CircleButton(
                  icon: Icons.home_rounded,
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
                if (nextScreen != null) ...[
                  const SizedBox(width: 18),
                  _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => nextScreen!),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFBFEFDD),
              Color(0xFFB8C9FF),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

class BubbleTailPainter extends CustomPainter {
  const BubbleTailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    path.moveTo(0, 0);
    path.quadraticBezierTo(
      size.width * 0.20,
      size.height * 0.10,
      size.width * 0.32,
      size.height * 0.72,
    );
    path.quadraticBezierTo(
      size.width * 0.48,
      size.height * 1.15,
      size.width * 0.76,
      size.height * 0.42,
    );
    path.quadraticBezierTo(
      size.width * 0.90,
      size.height * 0.18,
      size.width,
      0,
    );
    path.close();

    final paint = Paint()
      ..color = const Color(0xFFFFF3C4)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.save();
    canvas.translate(0, 4);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}