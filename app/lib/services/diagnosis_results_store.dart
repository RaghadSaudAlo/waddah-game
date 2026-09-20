class DiagnosisResultsStore {
  static final List<Map<String, dynamic>> _results = [];

  static List<Map<String, dynamic>> get results => List.unmodifiable(_results);

  static bool get hasResults => _results.isNotEmpty;

  static void addResult({
    required String word,
    required String targetPhoneme,
    required String position,
    required String producedPhoneme,
  }) {
    _results.add({
      'word': word,
      'target_phoneme': targetPhoneme,
      'position': position,
      'produced_phoneme': producedPhoneme,
    });
  }

  static void clear() {
    _results.clear();
  }
}