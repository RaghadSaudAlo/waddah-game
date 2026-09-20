/// Web implementation. See `recording_store.dart` for why this split exists.
///
/// On the web the `record` package ignores the path passed to `start()` and
/// returns a blob URL from `stop()`. The browser owns that blob and reclaims
/// it when the page goes away, so there is nothing for us to place or delete.
///
/// PDPL note: this is still compliant — the audio never leaves the browser tab
/// and is never uploaded. In the mock build nothing reads it at all.
Future<String> newRecordingPath() async => '';

Future<void> deleteRecording(String? path) async {
  // No-op: nothing was written to a filesystem we control.
}
