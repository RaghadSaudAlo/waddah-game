import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/diagnosis_audio_service.dart';
import '../services/mock_diagnosis_service.dart';
import 'correct_screen.dart';
import 'wrong_screen.dart';
import 'home_screen.dart';
import '../services/progress_store.dart';

import 'package:record/record.dart';
import '../services/diagnosis_results_store.dart';
// dart:io and path_provider are deliberately NOT imported here: both are
// unavailable on the web and would break `flutter build web`. See
// services/recording_store.dart.
import '../services/recording_store.dart';

class AnimalPromptScreen extends StatefulWidget {
  final String backgroundImage;
  final String characterImage;
  final String fullPromptText;
  final String wordOnlyText;
  final String targetPhoneme;
  final String position;
  final double characterLeft;
  final double characterBottom;
  final double characterWidth;
  final Widget? nextScreen;

  const AnimalPromptScreen({
    super.key,
    required this.backgroundImage,
    required this.characterImage,
    required this.fullPromptText,
    required this.wordOnlyText,
    required this.targetPhoneme,
    required this.position,
    this.characterLeft = 780,
    this.characterBottom = 90,
    this.characterWidth = 360,
    this.nextScreen,
  });

  @override
  State<AnimalPromptScreen> createState() => _AnimalPromptScreenState();
}

class _AnimalPromptScreenState extends State<AnimalPromptScreen>


    with SingleTickerProviderStateMixin {
  late final AnimationController _recordController;
  final DiagnosisAudioService _audioService = DiagnosisAudioService();

  bool isRecording = false;
  bool _hasPlayedInitialPrompt = false;
  Timer? _recordTimer;

  /// True while the diagnosis is in flight. Without this the screen froze with
  /// no feedback, which loses a 7-year-old; the mic is also locked so a second
  /// tap cannot start a new recording mid-request.
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();

    _recordController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
      lowerBound: 0.92,
      upperBound: 1.08,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_hasPlayedInitialPrompt) {
        _hasPlayedInitialPrompt = true;
        await _playFullPrompt();
      }
    });
  }

  @override
void dispose() {
  _recordTimer?.cancel();
  _recordController.dispose();
  _audioService.dispose();
  _audioRecorder.dispose();
  super.dispose();
}

  Future<void> _playFullPrompt() async {
    await _audioService.playText(widget.fullPromptText);
  }

  Future<void> _playWordOnly() async {
    await _audioService.playText(widget.wordOnlyText);
  }

  Future<void> _toggleRecording() async {
  if (isRecording) {
    await _stopRecording(showResult: true);
    return;
  }

  setState(() {
    isRecording = true;
  });

  _recordController.repeat(reverse: true);
  SystemSound.play(SystemSoundType.click);

  await _startRealRecording();

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('بدأ التسجيل لمدة 5 ثواني'),
      duration: Duration(seconds: 1),
    ),
  );

  _recordTimer?.cancel();
  _recordTimer = Timer(const Duration(seconds: 5), () async {
    if (mounted && isRecording) {
      await _stopRecording(showResult: true);
    }
  });
}

  Future<void> _stopRecording({bool showResult = false}) async {
  _recordTimer?.cancel();
  _recordController.stop();
  _recordController.value = 1.0;

  await _stopRealRecording();

  if (!mounted) return;

  setState(() {
    isRecording = false;
  });

  if (showResult) {
    // Show the thinking state for the whole round trip. The real Space can
    // take up to 60s to wake from sleep, so this must exist before the model
    // is wired in, not after.
    setState(() {
      _isThinking = true;
    });

    try {
      if (_recordedFilePath == null) {
  throw Exception('No recorded file found');
}

final result = await MockDiagnosisService.diagnoseWithAudio(
  audioPath: _recordedFilePath!,
  word: widget.wordOnlyText,
  phoneme: widget.targetPhoneme,
  position: widget.position,
);

final isCorrect = result['is_correct'] as bool;

ProgressStore.addAttempt(
  word: result['word']?.toString() ?? widget.wordOnlyText,
  targetPhoneme: result['target_phoneme']?.toString() ?? widget.targetPhoneme,
  position: result['position']?.toString() ?? widget.position,
  isCorrect: isCorrect,
  producedPhoneme: result['produced_phoneme']?.toString() ?? '',
);

if (!isCorrect) {
  DiagnosisResultsStore.addResult(
    word: result['word']?.toString() ?? widget.wordOnlyText,
    targetPhoneme: result['target_phoneme']?.toString() ?? widget.targetPhoneme,
    position: result['position']?.toString() ?? widget.position,
    producedPhoneme: result['produced_phoneme']?.toString() ?? '',
  );
}

// PDPL: the result is rendered, so the child's audio has served its purpose.
// Delete it now rather than leaving it for the OS to clear eventually.
await _discardRecording();

if (!mounted) return;
      setState(() {
        _isThinking = false;
      });
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => isCorrect
              ? CorrectScreen(
                  nextScreen: widget.nextScreen,
                  characterImage: widget.characterImage,
                )
              : WrongScreen(
                  nextScreen: widget.nextScreen,
                  characterImage: widget.characterImage,
                ),
        ),
      );
    } catch (e) {
      // Delete the recording on the failure path too, or a crashed request
      // would leave the child's voice on disk.
      await _discardRecording();

      if (!mounted) return;
      setState(() {
        _isThinking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Diagnosis error: $e')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            widget.backgroundImage,
            fit: BoxFit.cover,
          ),

          Positioned(
            left: widget.characterLeft,
            bottom: widget.characterBottom,
            child: Image.asset(
              widget.characterImage,
              width: widget.characterWidth,
              fit: BoxFit.contain,
            ),
          ),

          Positioned(
            top: 32,
            left: 24,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE08A),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ),
          ),

          Positioned(
            left: 300,
            bottom: 400,
            child: SizedBox(
              width: 520,
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
                      widget.fullPromptText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D2D2D),
                        height: 1.5,
                      ),
                    ),
                  ),

                  Positioned(
                    top: -18,
                    right: -18,
                    child: _SpeakerButton(
                      onTap: _playFullPrompt,
                    ),
                  ),

                  Positioned(
                    bottom: -22,
                    left: 170,
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

    // 🔹 زر الرجوع للهوم
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

    const SizedBox(width: 18),

    // 🎤 زر المايك — معطّل أثناء التحليل
    GestureDetector(
      // Locked while thinking: a second tap mid-request would start a new
      // recording on top of the one being diagnosed.
      onTap: _isThinking ? null : _toggleRecording,
      child: ScaleTransition(
        scale: isRecording
            ? _recordController
            : const AlwaysStoppedAnimation(1.0),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isRecording
                  ? const [
                      Color(0xFFFF4D4D),
                      Color(0xFFFF7A7A),
                    ]
                  : const [
                      Color(0xFFBFEFDD),
                      Color(0xFFB8C9FF),
                    ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mic_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    ),

    const SizedBox(width: 18),

    // 🔊 زر السبيكر
    _CircleButton(
      icon: Icons.volume_up_rounded,
      onTap: _playWordOnly,
    ),
  ],
),
          ),

          // وضّاح يفكّر — thinking state.
          // A free-tier Space can take up to 60s to wake, and a frozen screen
          // loses a 7-year-old. This must be on top of everything so the child
          // cannot tap through it while the request is in flight.
          if (_isThinking) const _ThinkingOverlay(),
        ],
      ),
    );
  }
  final AudioRecorder _audioRecorder = AudioRecorder();
String? _recordedFilePath;

Future<void> _startRealRecording() async {
  final hasPermission = await _audioRecorder.hasPermission();

  if (!hasPermission) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لا يوجد إذن لاستخدام الميكروفون')),
    );
    return;
  }

  // Privacy: temporary storage on mobile/desktop, never the documents
  // directory. On web this is '' and `record` manages its own blob.
  // See services/recording_store.dart.
  final path = await newRecordingPath();
  _recordedFilePath = path;

  // 16 kHz mono WAV is what the HuBERT CTC model was trained on. The previous
  // config (AAC-LC, 44.1 kHz) is a silent accuracy killer: it still "works",
  // the model just gets audio unlike anything it saw in training. Keeping the
  // format correct now means the real model can be dropped in without
  // re-testing the capture path.
  await _audioRecorder.start(
    const RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: 16000,
      numChannels: 1,
    ),
    path: path,
  );
}

Future<void> _stopRealRecording() async {
  final path = await _audioRecorder.stop();

  if (path != null) {
    _recordedFilePath = path;
  }
}

/// PDPL: delete the child's audio as soon as we are done with it. Nothing
/// about the child's voice persists on the device.
Future<void> _discardRecording() async {
  final path = _recordedFilePath;
  _recordedFilePath = null;
  await deleteRecording(path);
}

}

/// Full-screen "Waddah is thinking" state.
///
/// Deliberately a blocking overlay rather than a spinner in a corner: it also
/// stops the child tapping the character or the back button into an
/// inconsistent state while the diagnosis is running.
class _ThinkingOverlay extends StatefulWidget {
  const _ThinkingOverlay();

  @override
  State<_ThinkingOverlay> createState() => _ThinkingOverlayState();
}

class _ThinkingOverlayState extends State<_ThinkingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      // Absorb every tap so nothing underneath reacts mid-request.
      child: AbsorbPointer(
        child: ColoredBox(
          color: const Color(0xCC1B2B2B),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.06).animate(
                    CurvedAnimation(parent: _c, curve: Curves.easeInOut),
                  ),
                  child: Image.asset(
                    'assets/images/waddah.png',
                    width: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.pets_rounded,
                      size: 96,
                      color: Color(0xFFBFEFDD),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'وضّاح يفكّر...',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),
                const SizedBox(
                  width: 180,
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: Color(0x33FFFFFF),
                    valueColor: AlwaysStoppedAnimation(Color(0xFFBFEFDD)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeakerButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SpeakerButton({required this.onTap});

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