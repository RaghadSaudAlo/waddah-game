import 'dart:math' as math;

import '../data/word_bank.dart';

/// Replace [MockSpeechService.evaluate] body with a real model / API later.
class SpeechEvaluationResult {
  SpeechEvaluationResult({
    required this.correct,
    required this.confidence,
    required this.weakLetter,
  });

  final bool correct;
  final double confidence;
  final String weakLetter;
}

class MockSpeechService {
  MockSpeechService({math.Random? random}) : _r = random ?? math.Random();

  final math.Random _r;

  /// [forceOutcome] overrides randomness (tests / debug).
  SpeechEvaluationResult evaluate(
    String word, {
    bool? forceOutcome,
  }) {
    final correct = forceOutcome ?? _r.nextDouble() > 0.38;
    final confidence = correct
        ? 68 + _r.nextDouble() * 31
        : 22 + _r.nextDouble() * 38;
    final weak = WordBank.firstLetter(word);
    return SpeechEvaluationResult(
      correct: correct,
      confidence: confidence.clamp(4, 99),
      weakLetter: weak,
    );
  }

}
