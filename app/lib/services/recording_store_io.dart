import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Where a new recording is written.
///
/// Privacy: the TEMPORARY directory, never the documents directory. Documents
/// storage is backed up and persists indefinitely, which is the wrong place
/// for a child's voice.
Future<String> newRecordingPath() async {
  final dir = await getTemporaryDirectory();
  return '${dir.path}/utterance_${DateTime.now().millisecondsSinceEpoch}.wav';
}

/// PDPL: delete the child's audio the moment it has served its purpose.
Future<void> deleteRecording(String? path) async {
  if (path == null || path.isEmpty) return;
  try {
    final f = File(path);
    if (await f.exists()) await f.delete();
  } catch (e) {
    debugPrint('Could not delete recording: $e');
  }
}
