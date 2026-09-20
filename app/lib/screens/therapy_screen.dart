import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

// path_provider is not imported: it is unimplemented on the web and would
// break `flutter build web`. See services/recording_store.dart.
import '../services/recording_store.dart';
import '../services/user_profile_store.dart';

import '../services/diagnosis_audio_service.dart';
import '../services/therapy_service.dart';
import 'home_screen.dart';

import '../services/diagnosis_results_store.dart';

class TherapyScreen extends StatefulWidget {
  const TherapyScreen({super.key});

  @override
  State<TherapyScreen> createState() => _TherapyScreenState();
}

class _TherapyScreenState extends State<TherapyScreen> {
  bool isLoading = true;
  String? errorMessage;
  int? childAge;
final DiagnosisAudioService _audioService = DiagnosisAudioService();
bool hasPlayedIntro = false;

  List<Map<String, String>> therapyTargets = [];

  final Map<String, String> imageMap = {
  'أسد': 'assets/images/asad.png',
  'بطة': 'assets/images/battah.png',
  'تفاح': 'assets/images/tuffah.png',
  'ثعلب': 'assets/images/thalab.png',
  'جمل': 'assets/images/jamal.png',
  'مسبح': 'assets/images/masbah.png',
  'فيل': 'assets/images/fil.png',
};

@override
void initState() {
  super.initState();
  _initializeTherapy();
}

Future<void> _initializeTherapy() async {
  childAge = await UserProfileStore.getAge();
  await _loadTherapyTargets();
}

  Future<void> _loadTherapyTargets() async {
  try {
    final data = await TherapyService.getTherapyTargets(
      age: childAge ?? 6,
      diagnosisResults: DiagnosisResultsStore.hasResults
          ? DiagnosisResultsStore.results
          : [
              {
                'word': 'أسد',
                'target_phoneme': 'ء',
                'position': 'initial',
                'produced_phoneme': 'ا',
              },
            ],
    );

    final rawTargets = data['therapy_targets'];
    debugPrint('THERAPY TARGETS FROM BACKEND: $rawTargets');

    if (!mounted) return;

    setState(() {
      therapyTargets = rawTargets is List
          ? rawTargets.map<Map<String, String>>((item) {
              final word = item['word'].toString();

              return {
                'word': word,
                'targetPhoneme': item['target_phoneme'].toString(),
                'position': item['position'].toString(),
                'image': imageMap[word] ?? 'assets/images/waddah.png',
              };
            }).toList()
          : [];

      isLoading = false;
    });

    if (!hasPlayedIntro && therapyTargets.isNotEmpty) {
      hasPlayedIntro = true;
      await _audioService.playText('أي صديق تريد أن نتدرّب معه أولًا؟');
    }
  } catch (e) {
    if (!mounted) return;

    setState(() {
      errorMessage = e.toString();
      isLoading = false;
    });
  }
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

          Positioned(
            top: 32,
            left: 24,
            child: _TopCircleButton(
              icon: Icons.home_rounded,
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
            ),
          ),

          const Positioned(
            top: 38,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'تدرّب',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF27A9C9),
                ),
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 220,
            child: Center(
              child: Image.asset(
                'assets/images/waddah.png',
                width: 300,
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            top: 320,
            child: Center(
              child: Container(
                width: 650,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3C4),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  isLoading
                      ? 'وضاح يبحث عن الكلمات المناسبة...'
                      : therapyTargets.isEmpty
                          ? 'ممتاز! لا توجد كلمات تحتاج تدريب الآن '
                          : 'أي صديق تريد أن نتدرّب معه أولًا؟ ',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2D2D2D),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),

          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (errorMessage != null)
            Center(
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else
            Positioned(
              left: 50,
              right: 50,
              bottom: 35,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 24,
                runSpacing: 20,
                children: therapyTargets.map((item) {
                  return _therapyWordButton(
                    context: context,
                    word: item['word']!,
                    targetPhoneme: item['targetPhoneme']!,
                    image: item['image']!,
                    position: item['position']!,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _therapyWordButton({
    required BuildContext context,
    required String word,
    required String targetPhoneme,
    required String image,
    required String position,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TherapySessionView(
              selectedWord: word,
              targetPhoneme: targetPhoneme,
              characterImage: image,
              position: position,
            ),
          ),
        );
      },
      child: Column(
  children: [
    Transform.translate(
      offset: const Offset(0, -8),
      child: Container(
        width: 118,
        height: 118,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7DE),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFBFEFDD),
            width: 7,
          ),
        ),
        child: Center(
          child: Image.asset(
            image,
            width: 84,
          ),
        ),
      ),
    ),
    const SizedBox(height: 10),
    Text(
  word,
  style: const TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    color: Color(0xFF2D2D2D),
  ),
),
  ],
),
          
    );
  }
}
class TherapySessionView extends StatefulWidget {
  final String selectedWord;
  final String targetPhoneme;
  final String characterImage;
  final String position;

  const TherapySessionView({
    super.key,
    required this.selectedWord,
    required this.targetPhoneme,
    required this.characterImage,
    required this.position,
  });

  @override
  State<TherapySessionView> createState() => _TherapySessionViewState();
}

class _TherapySessionViewState extends State<TherapySessionView>
    with SingleTickerProviderStateMixin {
  final DiagnosisAudioService _audioService = DiagnosisAudioService();
  final AudioPlayer _feedbackPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();

  late final AnimationController _recordController;

  bool isLoading = true;
  bool isRecording = false;
  bool canGoNext = false;
  bool sessionFinished = false;
  int earnedStars = 0;

  List<Map<String, dynamic>> stages = [];

  int currentStageIndex = 0;
  int currentItemIndex = 0;

  String encouragementText = 'جاري تجهيز الجلسة...';
  String feedbackText = 'انتظر قليلًا';
  String hintText = '';

  String? _recordedFilePath;

  Map<String, dynamic> get currentStage {
    if (stages.isEmpty) {
      return {
        'stage': 'word',
        'title': 'كلمة تدريب',
        'items': [widget.selectedWord],
      };
    }
    return stages[currentStageIndex];
  }

  List<String> get currentItems {
    final rawItems = currentStage['items'];
    if (rawItems is List) {
      return rawItems.map((e) => e.toString()).toList();
    }
    return [widget.selectedWord];
  }

  String get currentText {
    final items = currentItems;
    if (items.isEmpty) return widget.selectedWord;
    return items[currentItemIndex];
  }

  String get currentStageTitle {
    return currentStage['title']?.toString() ?? 'جلسة تدريب';
  }

  int get totalSteps {
    int count = 0;
    for (final stage in stages) {
      final rawItems = stage['items'];
      if (rawItems is List) {
        count += rawItems.length;
      }
    }
    return count == 0 ? 1 : count;
  }

  int get currentStep {
    if (stages.isEmpty) return 1;

    int count = 0;
    for (int i = 0; i < currentStageIndex; i++) {
      final rawItems = stages[i]['items'];
      if (rawItems is List) {
        count += rawItems.length;
      }
    }

    return count + currentItemIndex + 1;
  }

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
      await _loadSessionPlan();
    });
  }

  @override
  void dispose() {
    _recordController.dispose();
    _audioService.dispose();
    _feedbackPlayer.dispose();
    _audioRecorder.dispose();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _loadSessionPlan() async {
    setState(() {
      isLoading = true;
      encouragementText = 'جاري تجهيز الجلسة...';
      feedbackText = 'وضاح يجهز كلمات التدريب';
      hintText = '';
    });

    try {
      final data = await TherapyService.getTherapySessionPlan(
        selectedWord: widget.selectedWord,
        targetPhoneme: widget.targetPhoneme,
        position: widget.position,
      );

      final rawStages = data['stages'];

      if (!mounted) return;

      setState(() {
        stages = rawStages is List
            ? rawStages
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];

        currentStageIndex = 0;
        currentItemIndex = 0;
        canGoNext = false;
        sessionFinished = false;

        encouragementText = 'لنبدأ ';
        feedbackText = 'استمع ثم قل معي: $currentText';
        hintText = currentStageTitle;
        isLoading = false;
      });

      await _playFeedback('لنبدأ التدريب، استمع جيدًا');
await Future.delayed(const Duration(seconds: 2));
await _playCurrentText();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        stages = [
          {
            'stage': 'word',
            'title': 'كلمة تدريب',
            'items': [widget.selectedWord],
          }
        ];

        encouragementText = 'صار خطأ';
        feedbackText = 'تعذر تحميل خطة التدريب';
        hintText = '$e';
        isLoading = false;
      });
    }
  }

  Future<void> _startRealRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();

    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد إذن لاستخدام الميكروفون')),
      );
      return;
    }

    // PDPL + web: temp directory instead of the documents directory (the old
    // path was never cleared), and no direct path_provider/dart:io use so the
    // web build compiles. See services/recording_store.dart.
    final path = await newRecordingPath();
    _recordedFilePath = path;

    // 16 kHz mono WAV — the format the CTC model was trained on. Matching the
    // diagnosis screen so both capture paths stay identical.
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

  /// PDPL: the therapy loop records too, so it must discard just as promptly.
  Future<void> _discardRecording() async {
    final path = _recordedFilePath;
    _recordedFilePath = null;
    await deleteRecording(path);
  }

  Future<void> _playCurrentText() async {
    await _audioService.playText(currentText);
  }

  Future<void> _playFeedback(String text) async {
    await _audioService.playText(text);
  }

  Future<void> _toggleRecording() async {
    if (isLoading || sessionFinished) return;

    if (isRecording) {
      await _stopRecordingAndEvaluate();
      return;
    }

    setState(() {
      isRecording = true;
      canGoNext = false;
      encouragementText = 'أنا أسمعك';
      feedbackText = 'استمع ثم قل معي: $currentText';
      hintText = '';
    });

    _recordController.repeat(reverse: true);
    SystemSound.play(SystemSoundType.click);

    await _startRealRecording();

    Timer(const Duration(seconds: 5), () async {
      if (mounted && isRecording) {
        await _stopRecordingAndEvaluate();
      }
    });
  }

  Future<void> _stopRecordingAndEvaluate() async {
    _recordController.stop();
    _recordController.value = 1.0;

    await _stopRealRecording();

    if (!mounted) return;

    setState(() {
      isRecording = false;
earnedStars++;
      canGoNext = true;
      encouragementText = 'أحسنت';
      feedbackText = 'محاولة جميلة، ننتقل للخطوة التالية';
      hintText = currentStageTitle;
    });

    await _playFeedback('أحسنت، محاولة جميلة');
  }

  Future<void> _goNext() async {
    if (sessionFinished) {
      Navigator.pop(context);
      return;
    }

    final items = currentItems;

    if (currentItemIndex < items.length - 1) {
      setState(() {
        currentItemIndex++;
        canGoNext = false;
        encouragementText = 'الخطوة التالية';
        feedbackText = 'استمع ثم قل: $currentText';
        hintText = currentStageTitle;
      });

      await _playFeedback('ممتاز، ننتقل للخطوة التالية');
await Future.delayed(const Duration(seconds: 1));
await _playCurrentText();
      return;
    }

    if (currentStageIndex < stages.length - 1) {
      setState(() {
        currentStageIndex++;
        currentItemIndex = 0;
        canGoNext = false;
        encouragementText = 'مرحلة جديدة ';
        feedbackText = 'الآن ننتقل إلى: $currentStageTitle';
        hintText = 'قل: $currentText';
      });

      await _playFeedback('مرحلة جديدة، $currentStageTitle');
await Future.delayed(const Duration(seconds: 2));
await _playCurrentText();
      return;
    }

    setState(() {
      sessionFinished = true;
      canGoNext = true;
      earnedStars += 2;
      encouragementText = 'انتهت الجلسة ';
      feedbackText = 'أحسنت جدًا، أنهيت تدريب اليوم';
      hintText = 'اضغط علامة الصح للعودة';
    });

    await _playFeedback('أحسنت جدًا، أنهيت تدريب اليوم');
  }

  @override
  Widget build(BuildContext context) {
    final progressValue = currentStep / totalSteps;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/home_screen.png',
            fit: BoxFit.cover,
          ),

          Positioned(
            top: 28,
            left: 24,
            right: 24,
            child: Row(
              children: [
                _TopCircleButton(
                  icon: Icons.home_rounded,
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(width: 12),
                _TopCircleButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const Spacer(),
                Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 10,
  ),
  decoration: BoxDecoration(
    color: const Color(0xFFFFE08A),
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.10),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: SizedBox(
    width: 180,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LinearProgressIndicator(
        value: progressValue.clamp(0.0, 1.0),
        minHeight: 12,
        backgroundColor: Colors.white,
        valueColor: const AlwaysStoppedAnimation<Color>(
          Color(0xFF27A9C9),
        ),
      ),
    ),
  ),
),
                    
              ],
            ),
          ),

          Positioned(
            top: 82,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                currentStageTitle,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF27A9C9),
                ),
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            top: 132,
            child: Center(
  child: Text(
    currentText,
    textAlign: TextAlign.center,
    style: const TextStyle(
      fontSize: 64,
      fontWeight: FontWeight.w900,
      color: Color(0xFF2D2D2D),
    ),
  ),
),
            ),
          

          Positioned(
  left: 300,
  right: 300,
  top: 225,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3C4),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    encouragementText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    feedbackText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D2D2D),
                      height: 1.5,
                    ),
                  ),
                  
                ],
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 235,
            child: Center(
              child: AnimatedScale(
  duration: const Duration(milliseconds: 300),
  scale: isRecording ? 1.12 : 1.0,
  child: Image.asset(
    widget.characterImage,
    width: 210,
    fit: BoxFit.contain,
  ),
),
            ),
          ),

          Positioned(
            left: 400,
            right: 400,
            bottom: 120,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7DE),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: currentItems.asMap().entries.map((entry) {
                  final isCurrent = entry.key == currentItemIndex;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFFBFEFDD)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFF27A9C9)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CircleButton(
                  icon: Icons.volume_up_rounded,
                  onTap: isLoading ? () {} : _playCurrentText,
                ),
                const SizedBox(width: 18),
                GestureDetector(
                  onTap: isLoading ? null : _toggleRecording,
                  child: ScaleTransition(
                    scale: isRecording
                        ? _recordController
                        : const AlwaysStoppedAnimation(1.0),
                    child: Container(
                      width: 78,
                      height: 78,
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
                        boxShadow: [
                          BoxShadow(
                            color: isRecording
                                ? const Color(0xFFFF4D4D).withOpacity(0.45)
                                : Colors.black.withOpacity(0.14),
                            blurRadius: isRecording ? 16 : 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.mic_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                _CircleButton(
                  icon: sessionFinished
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  onTap: canGoNext ? _goNext : () {},
                  isDisabled: !canGoNext,
                ),
              ],
            ),
          ),
Positioned(
  top: 40,
  left: 0,
  right: 0,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      earnedStars,
      (index) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Icon(
          Icons.star_rounded,
          color: Color(0xFFFFD54F),
          size: 50,
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

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDisabled;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.45 : 1,
        child: Container(
          width: 66,
          height: 66,
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
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
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
          size: 24,
          color: const Color(0xFF2D2D2D),
        ),
      ),
    );
  }
}