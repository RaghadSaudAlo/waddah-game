import 'dart:math' as math;

import 'mock_speech_service.dart';

/// Local diagnosis provider, used when the app runs without the model API.
///
/// It lets the whole game — recording, feedback, and the therapy flow that
/// follows a mispronunciation — be exercised end to end on a device with no
/// network and no credentials, which is what makes the app installable as a
/// self-contained build.
///
/// The response shape is deliberately the union of two contracts: the keys the
/// screens read today (`is_correct`, `produced_phoneme`) and the keys the
/// model API returns (`target_detection`, `diagnosis`, `confidence`). Swapping
/// in the live API is therefore a change at the call site, not a rewrite of
/// every screen.
///
/// Outcome selection is delegated to [MockSpeechService] so behaviour stays
/// consistent everywhere a local provider is used.
class MockDiagnosisService {
  MockDiagnosisService._();

  static final MockSpeechService _speech = MockSpeechService();
  static final math.Random _r = math.Random();

  /// Plausible substitutions a Saudi child actually makes. Same table as
  /// `TherapyService._mockProducedPhoneme`, kept in sync by hand.
  static const Map<String, String> _substitutions = {
    'ء': 'ا',
    'ف': 'ب',
    'ش': 'س',
    'ك': 'ت',
    'ر': 'ل',
    'س': 'ث',
    'ث': 'س',
    'ص': 'س',
    'ط': 'ت',
    'ق': 'ك',
    'ج': 'د',
    'ز': 'ذ',
    'ح': 'ه',
    'ع': 'ا',
  };

  /// Mirrors `DiagnosisService.diagnoseWithAudio`'s signature so the call site
  /// changes by one identifier. [audioPath] is accepted and ignored — the file
  /// is never read, never uploaded and never stored.
  static Future<Map<String, dynamic>> diagnoseWithAudio({
    required String audioPath,
    required String word,
    required String phoneme,
    required String position,
    bool? forceOutcome,
  }) async {
    // A short delay so the "thinking" state is actually visible; without it the
    // character would flash for one frame and the screen would look broken.
    await Future<void>.delayed(
      Duration(milliseconds: 700 + _r.nextInt(600)),
    );

    final evaluation = _speech.evaluate(word, forceOutcome: forceOutcome);
    final isCorrect = evaluation.correct;
    final produced =
        isCorrect ? phoneme : (_substitutions[phoneme] ?? phoneme);

    return <String, dynamic>{
      // --- keys the current screens read ---
      'success': true,
      'word': word,
      'target_phoneme': phoneme,
      'position': position,
      'produced_phoneme': produced,
      'is_correct': isCorrect,
      'message': isCorrect ? 'أحسنت!' : 'محاولة جميلة',

      // --- keys the real API will return (api/schemas.py) ---
      'target_detection': isCorrect ? 'normal' : 'abnormal',
      'diagnosis': isCorrect ? 'correct' : 'substitution',
      'confidence': (evaluation.confidence / 100).clamp(0.0, 1.0),
      'mock': true,
    };
  }
}
