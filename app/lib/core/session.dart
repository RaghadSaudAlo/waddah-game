import 'package:flutter/foundation.dart';

class AppSession extends ChangeNotifier {
  String username = '';
  int childAge = 7;
  String email = '';
  String password = '';

  int score = 0;
  int attempts = 0;
  final List<String> wordsCorrect = [];
  final List<String> wordsIncorrect = [];
  final Map<String, int> weakLetterFrequency = {};
  double _confidenceSum = 0;
  int _confidenceN = 0;

  double get averageConfidence =>
      _confidenceN == 0 ? 0 : _confidenceSum / _confidenceN;

  void applyLogin({
    required String username,
    required int age,
    required String email,
    required String password,
  }) {
    this.username = username;
    childAge = age;
    this.email = email;
    this.password = password;
    notifyListeners();
  }

  void recordEvaluation({
    required String word,
    required bool correct,
    required double confidence,
    required String weakLetter,
  }) {
    attempts++;
    _confidenceSum += confidence;
    _confidenceN++;
    if (correct) {
      score += 15;
      if (!wordsCorrect.contains(word)) {
        wordsCorrect.add(word);
      }
      wordsIncorrect.remove(word);
    } else {
      if (!wordsIncorrect.contains(word)) {
        wordsIncorrect.add(word);
      }
      weakLetterFrequency[weakLetter] =
          (weakLetterFrequency[weakLetter] ?? 0) + 1;
    }
    notifyListeners();
  }

  List<MapEntry<String, int>> get sortedWeakLetters {
    final list = weakLetterFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  double get pronunciationAccuracyPercent {
    if (attempts == 0) return 0;
    final ok = wordsCorrect.length;
    final total = wordsCorrect.length + wordsIncorrect.length;
    if (total == 0) return 0;
    return (ok / total * 100).clamp(0, 100);
  }

  void resetProgress() {
    score = 0;
    attempts = 0;
    wordsCorrect.clear();
    wordsIncorrect.clear();
    weakLetterFrequency.clear();
    _confidenceSum = 0;
    _confidenceN = 0;
    notifyListeners();
  }
}
