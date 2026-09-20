import '../data/word_bank.dart';

/// Stage titles spoken as 'مرحلة جديدة، $title'.
///
/// This list is a CLOSED SET on purpose. That line interpolates the title, and
/// the deployed build can only speak text that was pre-baked, so an unbaked
/// title plays as silence. These strings must stay byte-identical to the list
/// in `tools/generate_audio.py`.
const List<String> kTherapyStageTitles = <String>[
  'كلمات قصيرة',
  'كلمات أطول',
  'تدريب أخير',
];

/// Builds a practice session locally, without the therapy API.
///
/// Method names and return shapes match the remote service exactly, so the
/// bodies can be swapped for HTTP calls without any screen changing.
///
/// Word selection reuses [WordBank.wordsForWeakLetter] rather than duplicating
/// the logic, and every item is a bare lexicon word — exactly the set that has
/// bundled audio, so no step of the session is silent.
class TherapyService {
  TherapyService._();

  /// Small pause so the UI's loading state is visible rather than flickering.
  static Future<void> _tick() =>
      Future<void>.delayed(const Duration(milliseconds: 350));

  /// Shape matches the old `/therapy-session-plan` response: `{'stages': [...]}`
  /// where each stage is `{'stage', 'title', 'items'}`.
  static Future<Map<String, dynamic>> getTherapySessionPlan({
    required String selectedWord,
    required String targetPhoneme,
    String position = 'initial',
  }) async {
    await _tick();

    // Candidate words for this phoneme, selected word always first so the
    // child starts on the one they just failed.
    final pool = <String>{
      selectedWord,
      ...WordBank.wordsForWeakLetter(targetPhoneme),
    }.toList();

    List<String> slice(int start, int count) {
      if (pool.isEmpty) return <String>[selectedWord];
      final out = <String>[];
      for (var i = 0; i < count; i++) {
        out.add(pool[(start + i) % pool.length]);
      }
      return out.toSet().toList();
    }

    return <String, dynamic>{
      'stages': <Map<String, dynamic>>[
        {'stage': 'word', 'title': kTherapyStageTitles[0], 'items': slice(0, 3)},
        {'stage': 'word', 'title': kTherapyStageTitles[1], 'items': slice(3, 3)},
        {'stage': 'word', 'title': kTherapyStageTitles[2], 'items': slice(6, 3)},
      ],
      'mock': true,
    };
  }

  /// Shape matches the old `/therapy-targets` response:
  /// `{'therapy_targets': [{'word', 'target_phoneme', 'position'}, ...]}`.
  ///
  /// [age] is accepted so the signature is unchanged. The age-gating rules
  /// lived in the backend's `age_rules.py`; the mock does not reimplement them,
  /// it simply returns what the child actually got wrong.
  static Future<Map<String, dynamic>> getTherapyTargets({
    required int age,
    required List<Map<String, dynamic>> diagnosisResults,
  }) async {
    await _tick();

    final seen = <String>{};
    final targets = <Map<String, dynamic>>[];

    for (final r in diagnosisResults) {
      final word = r['word']?.toString() ?? '';
      if (word.isEmpty || !seen.add(word)) continue;
      targets.add(<String, dynamic>{
        'word': word,
        'target_phoneme': r['target_phoneme']?.toString() ?? '',
        'position': r['position']?.toString() ?? 'initial',
      });
    }

    // Never hand the therapy screen an empty list — it would show a blank
    // chooser with no way forward.
    if (targets.isEmpty) {
      targets.add(<String, dynamic>{
        'word': 'أسد',
        'target_phoneme': 'ء',
        'position': 'initial',
      });
    }

    return <String, dynamic>{'therapy_targets': targets, 'mock': true};
  }

  /// Kept so any older screen still compiles. The deployed build has no TTS
  /// service, so there is no audio_url to return — the caller falls back to
  /// the bundled clips via [DiagnosisAudioService].
  static Future<Map<String, dynamic>> getTherapyWithAudio({
    required String word,
    required String targetPhoneme,
  }) async {
    await _tick();
    return <String, dynamic>{
      'success': true,
      'therapy_output': <String, dynamic>{
        'tts_text': 'أحسنت، محاولة جميلة',
        'audio_url': null,
      },
      'mock': true,
    };
  }
}
