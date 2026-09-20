class ProgressStore {
  static final List<Map<String, dynamic>> _attempts = [];

  static List<Map<String, dynamic>> get attempts => List.unmodifiable(_attempts);

  static void addAttempt({
    required String word,
    required String targetPhoneme,
    required String position,
    required bool isCorrect,
    String producedPhoneme = '',
  }) {
    _attempts.add({
      'word': word,
      'target_phoneme': targetPhoneme,
      'position': position,
      'is_correct': isCorrect,
      'produced_phoneme': producedPhoneme,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static int get totalAttempts => _attempts.length;

  static int get correctAttempts =>
      _attempts.where((item) => item['is_correct'] == true).length;

  static int get wrongAttempts =>
      _attempts.where((item) => item['is_correct'] == false).length;

  static double get accuracy {
    if (_attempts.isEmpty) return 0;
    return correctAttempts / totalAttempts;
  }
}