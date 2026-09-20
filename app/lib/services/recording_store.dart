/// Platform-neutral handle on the child's temporary recording.
///
/// WHY THIS INDIRECTION EXISTS
/// `dart:io` does not exist on the web, and importing it anywhere in the
/// reachable tree fails the whole `flutter build web`. `path_provider`'s
/// directory lookups are likewise unimplemented there. The screens therefore
/// must not touch either directly.
///
/// On IO platforms the recording is a real file in the temp directory that we
/// delete explicitly. On the web the `record` package hands back a blob URL
/// that it owns and the browser reclaims; there is no file to place or delete,
/// so both calls are no-ops.
export 'recording_store_web.dart'
    if (dart.library.io) 'recording_store_io.dart';
