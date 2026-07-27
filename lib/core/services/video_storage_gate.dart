import 'package:flutter/foundation.dart';

import 'package:breakdex/core/services/app_storage_paths.dart';

/// Enforces that video files are only written to designated storage directories.
///
/// Any path outside the allowed directories is rejected — this prevents videos
/// from being accidentally saved to temporary caches, external volumes, or
/// other unintended locations.
abstract final class VideoStorageGate {
  static String? _docsPath;

  /// Must be called once at startup before any validation.
  static Future<void> initialize() async {
    final dir = await AppStoragePaths.documentsDirectory();
    _docsPath = dir.path;
  }

  /// Test-only override.
  @visibleForTesting
  static set docsPathOverride(final String path) => _docsPath = path;

  /// Allowed relative directories under the documents path.
  /// Videos must reside in one of these.
  static const _allowedSubdirs = <String>[
    'Moves',
    '.breakdex-master',
  ];

  /// Returns true if [path] is within an allowed storage directory.
  ///
  /// Rejects null, absolute paths outside documents, and anything not under
  /// the designated subdirectories.
  static bool isAllowed(final String? path) {
    if (path == null || path.isEmpty) return false;
    if (_docsPath == null) {
      debugPrint('[VideoStorageGate] Not initialized — rejecting path');
      return false;
    }

    final docs = _docsPath!;
    final absolute = path.startsWith('/') ? path : '$docs/$path';

    if (!absolute.startsWith(docs)) {
      debugPrint('[VideoStorageGate] BLOCKED: path outside documents dir — $absolute');
      return false;
    }

    final relative = absolute.substring(docs.length);
    final normalized = relative.startsWith('/') ? relative.substring(1) : relative;

    for (final subdir in _allowedSubdirs) {
      if (normalized == subdir || normalized.startsWith('$subdir/')) {
        return true;
      }
    }

    debugPrint('[VideoStorageGate] BLOCKED: not in allowed dirs — $normalized');
    return false;
  }

  /// Asserts [path] is allowed. Throws [VideoStorageViolation] if not.
  static void assertAllowed(final String? path) {
    if (!isAllowed(path)) {
      throw VideoStorageViolation(
        'Video path "$path" is outside the designated storage directories. '
        'Videos must reside under Moves/ or .breakdex-master/.',
      );
    }
  }

  /// Enforces that [destinationPath] is within allowed directories before
  /// allowing a write operation to proceed.
  static void guardWrite(final String? destinationPath) {
    assertAllowed(destinationPath);
  }
}

class VideoStorageViolation implements Exception {
  final String message;
  const VideoStorageViolation(this.message);

  @override
  String toString() => 'VideoStorageViolation: $message';
}
