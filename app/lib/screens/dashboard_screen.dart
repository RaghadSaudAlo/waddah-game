import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../services/progress_store.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedTab = 0;

int get totalAttempts => ProgressStore.totalAttempts;
int get correctAttempts => ProgressStore.correctAttempts;
int get wrongAttempts => ProgressStore.wrongAttempts;

double get pronunciationAccuracy => ProgressStore.accuracy;

double get modelConfidence => totalAttempts == 0 ? 0 : 0.91;

List<Map<String, String>> get spokenWords {
  return ProgressStore.attempts.reversed.take(3).map((item) {
    return {
      'emoji': item['is_correct'] == true ? '✅' : '🔁',
      'word': item['word']?.toString() ?? '',
    };
  }).toList();
}

List<String> get weakLetters {
  final counts = <String, int>{};

  for (final item in ProgressStore.attempts) {
    if (item['is_correct'] == false) {
      final letter = item['target_phoneme']?.toString() ?? '';
      if (letter.isNotEmpty) {
        counts[letter] = (counts[letter] ?? 0) + 1;
      }
    }
  }

  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted.map((e) => e.key).take(3).toList();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/progress_dashboard.png',
            fit: BoxFit.cover,
          ),

          Positioned(
            top: 28,
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

          // العنوان
          const Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'لوحة التقدم',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF27A9C9),
                ),
              ),
            ),
          ),

          // التابات
          Positioned(
            top: 108,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3C4).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _tabButton(
                      title: 'الأخصائي',
                      isSelected: selectedTab == 1,
                      onTap: () {
                        setState(() {
                          selectedTab = 1;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _tabButton(
                      title: 'ولي الأمر',
                      isSelected: selectedTab == 0,
                      onTap: () {
                        setState(() {
                          selectedTab = 0;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // البوكسات
          Positioned(
            top: 190,
            left: 70,
            right: 70,
            bottom: 110,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _parentOrSpecialistBox(
                          title: 'عدد المحاولات',
                          icon: '🔄',
                          child: selectedTab == 0
                              ? _attemptsContent(totalAttempts)
                              : _attemptsSpecialistContent(
  totalAttempts,
  correctAttempts,
  wrongAttempts,
),
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: _parentOrSpecialistBox(
                          title: selectedTab == 0
                              ? 'الكلمات التي نطقها الطفل'
                              : 'نسبة النطق الصحيح',
                          icon: selectedTab == 0 ? '🗣️' : '⭐',
                          child: selectedTab == 0
                              ? _spokenWordsContent()
                              : _progressBarContent(
                                  percentage:
                                      (pronunciationAccuracy * 100).toInt(),
                                  barColor: const Color(0xFF2DA9C8),
                                  fillColor: const Color(0xFF7BE06C),
                                  iconEmoji: '⭐',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _parentOrSpecialistBox(
                          title: selectedTab == 0
                              ? 'الحروف المجتازة'
                              : 'متوسط ثقة النموذج',
                          icon: selectedTab == 0 ? '🔤' : '👍🏻',
                          child: selectedTab == 0
                              ? _passedLettersContent()
                              : _progressBarContent(
                                  percentage: (modelConfidence * 100).toInt(),
                                  barColor: const Color(0xFF2DA9C8),
                                  fillColor: const Color(0xFF7BE06C),
                                  iconEmoji: '👍🏻',
                                ),
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: _parentOrSpecialistBox(
                          title: selectedTab == 0
                              ? 'الحروف التي تحتاج تدريب'
                              : 'الحروف الأكثر تعثرًا',
                          icon: '🔠',
                          child: selectedTab == 0
                              ? _needsPracticeContent()
                              : _specialistWeakLettersContent(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 22,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: Container(
                  width: 78,
                  height: 78,
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
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 150,
        height: 56,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFFBFEFDD),
                    Color(0xFFB8C9FF),
                  ],
                )
              : null,
          color: isSelected ? null : const Color(0xFFFFE08A),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isSelected ? Colors.white : const Color(0xFF2D2D2D),
          ),
        ),
      ),
    );
  }

  Widget _parentOrSpecialistBox({
    required String title,
    required String icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DE).withOpacity(0.93),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9E7A00).withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF2E4A8),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 28),
              ),
              const Spacer(),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF27A9C9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFE5C94C),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _attemptsContent(int attempts) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$attempts',
          style: const TextStyle(
            fontSize: 86,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFF9A8B),
            height: 1,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'محاولات',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFF6F6F),
          ),
        ),
      ],
    );
  }

  Widget _attemptsSpecialistContent(int attempts, int correct, int wrong) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _smallMetricRow('الإجمالي', '$attempts'),
        const SizedBox(height: 14),
        _smallMetricRow('صحيح', '$correct'),
        const SizedBox(height: 14),
        _smallMetricRow('خطأ', '$wrong'),
      ],
    );
  }

  Widget _smallMetricRow(String label, String value) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const Spacer(),
        Text(
          label,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D2D2D),
          ),
        ),
      ],
    );
  }

  Widget _spokenWordsContent() {
  if (spokenWords.isEmpty) {
    return const Center(
      child: Text(
        'لا توجد محاولات بعد',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2D2D2D),
        ),
      ),
    );
  }

  return Column(
    children: spokenWords.map((item) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFE7D999).withOpacity(0.7),
                  width: 1.2,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  item['emoji']!,
                  style: const TextStyle(fontSize: 34),
                ),
                const Spacer(),
                Text(
                  item['word']!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF27A9C9),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _passedLettersContent() {
  final passedLetters = ProgressStore.attempts
      .where((item) => item['is_correct'] == true)
      .map((item) => item['target_phoneme']?.toString() ?? '')
      .where((letter) => letter.isNotEmpty)
      .toSet()
      .take(3)
      .toList();

  if (passedLetters.isEmpty) {
    return const Center(
      child: Text(
        'لا توجد حروف مجتازة بعد',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2D2D2D),
        ),
      ),
    );
  }

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: passedLetters.map((letter) {
      return _letterBubble(letter, const Color(0xFF87CFFF));
    }).toList(),
  );
}

  Widget _letterBubble(String letter, Color color) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E8),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFF2E4A8),
          width: 3,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _needsPracticeContent() {
  if (weakLetters.isEmpty) {
    return const Center(
      child: Text(
        'لا توجد حروف تحتاج تدريب الآن',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2D2D2D),
        ),
      ),
    );
  }

  return Column(
    children: weakLetters.map((letter) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: LinearProgressIndicator(
                  value: 0.55,
                  minHeight: 16,
                  backgroundColor: const Color(0xFFFFEFC0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF7EC8E3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE08A),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

  Widget _specialistWeakLettersContent() {
  final counts = <String, int>{};

  for (final item in ProgressStore.attempts) {
    if (item['is_correct'] == false) {
      final letter = item['target_phoneme']?.toString() ?? '';
      if (letter.isNotEmpty) {
        counts[letter] = (counts[letter] ?? 0) + 1;
      }
    }
  }

  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  if (sorted.isEmpty) {
    return const Center(
      child: Text(
        'لا توجد تعثرات بعد',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2D2D2D),
        ),
      ),
    );
  }

  return Column(
    children: sorted.take(3).map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: _specialistWeakRow(entry.key, entry.value),
      );
    }).toList(),
  );
}

  Widget _specialistWeakRow(String letter, int count) {
    return Row(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: LinearProgressIndicator(
              value: count / 5,
              minHeight: 16,
              backgroundColor: const Color(0xFFFFEFC0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFFA07A),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFFFE08A),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2D2D2D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _progressBarContent({
    required int percentage,
    required Color barColor,
    required Color fillColor,
    required String iconEmoji,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Color(0xFF27A9C9),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFFFFEFC0),
                  border: Border.all(
                    color: barColor,
                    width: 2,
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: percentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [
                            barColor,
                            fillColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          iconEmoji,
          style: const TextStyle(fontSize: 58),
        ),
      ],
    );
  }
}