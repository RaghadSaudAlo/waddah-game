import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Resolves a spoken Arabic line to a bundled mp3 asset.
///
/// Why this exists: the app used to POST every line to
/// `http://127.0.0.1:8002/diagnosis-prompt-audio`, which called ElevenLabs and
/// returned a URL. That needs a live server and a live API key — neither of
/// which a Firebase-hosted demo should depend on. Every line is now generated
/// ahead of time by `tools/generate_audio.py` and shipped as an asset, so the
/// deployed build makes no network calls and carries no secrets.
///
/// The manifest is keyed on the EXACT text passed to [assetFor], which is why
/// the existing `playText('...')` call sites did not have to change. If you
/// edit a prompt string in Dart, add the same string to
/// `tools/generate_audio.py` and re-run it, or that line goes silent.
class LocalAudioService {
  LocalAudioService._();

  static const String _manifestPath = 'assets/audio/audio_manifest.json';

  static Map<String, String>? _manifest;
  static bool _loadFailed = false;

  /// Loads the manifest once and caches it.
  static Future<Map<String, String>> _load() async {
    if (_manifest != null) return _manifest!;
    if (_loadFailed) return const {};
    try {
      final raw = await rootBundle.loadString(_manifestPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _manifest = decoded.map((k, v) => MapEntry(k, v as String));
      return _manifest!;
    } catch (_) {
      // Audio not baked yet. Deliberately non-fatal: the app stays usable and
      // silent rather than crashing on a missing asset bundle.
      _loadFailed = true;
      return const {};
    }
  }

  /// Full asset path for [text], or null when that line has no baked audio.
  static Future<String?> assetFor(String text) async {
    final m = await _load();
    final file = m[text];
    return file == null ? null : 'assets/audio/$file';
  }

  /// True when at least one clip is bundled.
  static Future<bool> get isAvailable async => (await _load()).isNotEmpty;

  /// Number of baked lines — used by the debug banner and tests.
  static Future<int> get count async => (await _load()).length;
}
