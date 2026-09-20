import 'local_audio_service.dart';

/// Resolves a spoken line to a playable audio source.
///
/// Speech is generated ahead of time by `tools/generate_audio.py` and shipped
/// as assets, so this is a manifest lookup rather than a network call. That
/// keeps the app working offline and keeps API credentials out of the build
/// entirely.
///
/// Returns an ASSET PATH, which is why [DiagnosisAudioService] plays it with
/// `setAsset`. A line with no bundled clip returns null, and callers treat
/// null as "stay silent" rather than as an error.
class AudioService {
  AudioService._();

  static Future<String?> getPromptAudio(String text) =>
      LocalAudioService.assetFor(text);
}
