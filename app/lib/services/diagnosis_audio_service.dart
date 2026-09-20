import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_service.dart';

/// Plays a spoken Arabic line from the bundled assets.
///
/// Uses `setAsset` because [AudioService] resolves to an asset path — the
/// audio ships with the app rather than being fetched at runtime.
///
/// A line with no matching clip is not an error: the app stays usable and
/// simply stays silent. Audio coverage is verified separately by
/// `tools/check_audio_coverage.py`.
class DiagnosisAudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  Future<void> playText(String text) async {
    try {
      if (_isPlaying) {
        await _player.stop();
      }

      _isPlaying = true;

      final assetPath = await AudioService.getPromptAudio(text);

      if (assetPath == null || assetPath.isEmpty) {
        debugPrint('No baked audio for: "$text" — staying silent');
        return;
      }

      await _player.setAsset(assetPath);
      await _player.play();
    } catch (e) {
      debugPrint('DiagnosisAudioService error: $e');
    } finally {
      _isPlaying = false;
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
