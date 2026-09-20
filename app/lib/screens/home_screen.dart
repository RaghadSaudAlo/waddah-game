import 'package:flutter/material.dart';
import 'lion_screen.dart';
import 'dashboard_screen.dart';
import 'therapy_screen.dart';
import 'elephant_screen.dart';
import 'sun_screen.dart';
import 'book_screen.dart';
import 'phonemes_library_screen.dart';

import 'profile_screen.dart';

import '../services/user_profile_store.dart';
import '../services/diagnosis_audio_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool showIntroBubble = false;
  String childName = '';
  final DiagnosisAudioService audio = DiagnosisAudioService();

  @override
void initState() {
  super.initState();
  _loadChildName();
}

Future<void> _loadChildName() async {
  final name = await UserProfileStore.getUsername();

  if (!mounted) return;

  setState(() {
    childName = name;
  });
}

  String get _introText {
  final displayName =
      childName.trim().isEmpty ? 'يا صديقي' : 'يا $childName';

  return 'أهلًا $displayName \nأنا صديقك وضاح، هؤلاء أصدقائي، هيا بنا نتعرف عليهم!';
}

  Future<void> _playIntroAudio() async {
  // The SPOKEN greeting is name-less; the on-screen greeting above still uses
  // the child's name. The deployed build can only speak pre-baked lines, and a
  // name cannot be baked — interpolating one here produced a manifest miss and
  // the whole greeting played as silence. This string must stay byte-identical
  // to the one in tools/generate_audio.py.
  await audio.playText(
    'أهلًا يا صديقي، أنا صديقك وَضّاح، هؤلاء أصدقائي، هيا بنا نتعرف عليهم',
  );
}

  @override
  void dispose() {
    audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/home_screen.png',
            fit: BoxFit.cover,
          ),

          // الشريط العلوي
          Positioned(
            top: 38,
            left: 24,
            right: 24,
            child: Row(
              children: [
                _iconOnlyButton(
  icon: Icons.person_rounded,
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  },
),
                const Spacer(),
                _iconOnlyButton(
  icon: Icons.apps_rounded,
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PhonemesLibraryScreen(),
      ),
    );
  },
),
                const SizedBox(width: 14),
                _iconOnlyButton(
                  icon: Icons.bar_chart_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DashboardScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 14),
                _topButton(
                  label: 'تدرّب',
                  icon: Icons.auto_fix_high_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TherapyScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // الشخصيات الحالية
          Positioned(
            left: 70,
            bottom: 140,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LionScreen(),
                  ),
                );
              },
              child: Image.asset(
                'assets/images/asad.png',
                width: 300,
              ),
            ),
          ),

          Positioned(
            left: 300,
            bottom: 118,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SunScreen(),
                  ),
                );
              },
              child: Image.asset(
                'assets/images/shams.png',
                width: 200,
              ),
            ),
          ),

          Positioned(
            right: 300,
            bottom: 100,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BookScreen(),
                  ),
                );
              },
              child: Image.asset(
                'assets/images/kitab.png',
                width: 150,
              ),
            ),
          ),

          Positioned(
            right: 70,
            bottom: 122,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ElephantScreen(),
                  ),
                );
              },
              child: Image.asset(
                'assets/images/fil.png',
                width: 250,
              ),
            ),
          ),

          // -----------------------------------------
          // أماكن جاهزة تضيفين فيها الشخصيات الجديدة
          // بعد ما ترفعين الصور وتسوين الشاشات الخاصة فيها
          // -----------------------------------------

          // مثال عسل
          // Positioned(
          //   left: 180,
          //   bottom: 40,
          //   child: GestureDetector(
          //     onTap: () {
          //       // Navigator.of(context).push(
          //       //   MaterialPageRoute(
          //       //     builder: (_) => const HoneyScreen(),
          //       //   ),
          //       // );
          //     },
          //     child: Image.asset(
          //       'assets/images/asal.png',
          //       width: 140,
          //     ),
          //   ),
          // ),

          // مثال برتقال
          // Positioned(
          //   right: 180,
          //   bottom: 35,
          //   child: GestureDetector(
          //     onTap: () {
          //       // Navigator.of(context).push(
          //       //   MaterialPageRoute(
          //       //     builder: (_) => const OrangeScreen(),
          //       //   ),
          //       // );
          //     },
          //     child: Image.asset(
          //       'assets/images/burtuqal.png',
          //       width: 150,
          //     ),
          //   ),
          // ),

          // وضاح بالنص
          Positioned(
            left: 0,
            right: 0,
            bottom: 130,
            child: Center(
              child: Image.asset(
                'assets/images/waddah.png',
                width: 400,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // غيمة الكلام
          if (showIntroBubble)
            Positioned(
              left: 560,
              bottom: 300,
              child: SizedBox(
                width: 470,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 24, 80, 22),
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
                      child: Text(
                        _introText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2D2D2D),
                          height: 1.5,
                        ),
                      ),
                    ),

                    // السبيكر على زاوية الغيمة
                    Positioned(
                      top: -18,
                      right: -18,
                      child: _BubbleSpeakerButton(
                        onTap: _playIntroAudio,
                      ),
                    ),

                    // ذيل الغيمة
                    Positioned(
                      bottom: -15,
                      left: 95,
                      child: CustomPaint(
                        size: const Size(54, 30),
                        painter: BubbleTailPainter(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // زر ابدأ قبل الغيمة
          if (!showIntroBubble)
            Positioned(
              left: 0,
              right: 0,
              bottom: 42,
              child: Center(
                child: GestureDetector(
                  onTap: () async {
                    setState(() {
                      showIntroBubble = true;
                    });

                    await _playIntroAudio();
                  },
                  child: Container(
                    width: 340,
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
                      'ابدأ',
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

          // هيا بنا بعد ظهور الغيمة
          if (showIntroBubble)
            Positioned(
              left: 0,
              right: 0,
              bottom: 35,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LionScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 340,
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
                      'هيا بنا',
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

  Widget _iconOnlyButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE08A),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 30,
          color: const Color(0xFF2D2D2D),
        ),
      ),
    );
  }

  Widget _topButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 75,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE08A),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF2D2D2D)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D2D2D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleSpeakerButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BubbleSpeakerButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE08A),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.volume_up_rounded,
          size: 21,
          color: Color(0xFF2D2D2D),
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