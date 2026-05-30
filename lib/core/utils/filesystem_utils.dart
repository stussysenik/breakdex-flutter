import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Utilities for robust filesystem operations across platforms.
abstract final class FileSystemUtils {
  /// Safely moves a file from [sourcePath] to [destinationPath].
  ///
  /// On iOS/Android, [File.rename] can fail if the source and destination are
  /// on different partitions (e.g. from a temporary directory to the documents
  /// directory). This method implements a "Copy-and-Delete" fallback to ensure
  /// the move succeeds regardless of filesystem boundaries.
  static Future<File> safeMove(String sourcePath, String destinationPath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('Source file does not exist', sourcePath);
    }

    // Ensure the destination directory exists
    final destFile = File(destinationPath);
    final destDir = destFile.parent;
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }

    try {
      // 1. Try renaming first (atomic and fast if on the same partition)
      return await source.rename(destinationPath);
    } on FileSystemException catch (e) {
      // 2. If rename fails (common on iOS/Android across partitions),
      // fallback to copy-and-delete.
      debugPrint('[FileSystemUtils] rename failed ($e), falling back to copy/delete');
      
      // Perform the copy
      final copied = await source.copy(destinationPath);
      
      // Verify the copy exists and has bytes before deleting the original
      if (await copied.exists() && (await copied.length()) > 0) {
        await source.delete();
        return copied;
      } else {
        throw FileSystemException(
          'Copy failed or resulted in an empty file',
          destinationPath,
        );
      }
    }
  }

  /// Recursively delete empty parent directories starting from [filePath]'s
  /// parent, walking up until a non-empty directory or the [stopDir] is reached.
  ///
  /// This prevents accumulating ghost directories when video files are deleted.
  /// Each level is only removed if it contains zero entries (files + subdirs).
  ///
  /// [stopDir] is a path below which we never ascend (e.g., the documents or
  /// Moves root). Directories at or above [stopDir] are preserved.
  static Future<void> pruneEmptyParents(
    String filePath, {
    required String stopDir,
  }) async {
    var current = Directory(p.dirname(filePath));
    final normalizedStop = stopDir.endsWith('/')
        ? stopDir.substring(0, stopDir.length - 1)
        : stopDir;

    while (true) {
      final currentPath = current.path;
      if (currentPath == normalizedStop ||
          !currentPath.startsWith(normalizedStop)) {
        break;
      }

      try {
        if (!await current.exists()) {
          current = current.parent;
          continue;
        }
        final entries = await current.list().toList();
        if (entries.isEmpty) {
          await current.delete();
          debugPrint('[FileSystemUtils] Pruned empty dir: ${current.path}');
          current = current.parent;
        } else {
          break;
        }
      } catch (e) {
        debugPrint('[FileSystemUtils] Prune failed (non-fatal): $e');
        break;
      }
    }
  }
}
