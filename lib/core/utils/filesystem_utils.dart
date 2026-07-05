// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'diagnostics.dart';

/// Utilities for robust filesystem operations across platforms.
abstract final class FileSystemUtils {
  /// Safely moves a file from [sourcePath] to [destinationPath].
  ///
  /// On iOS/Android, [File.rename] can fail if the source and destination are
  /// on different partitions (e.g. from a temporary directory to the documents
  /// directory). This method implements a "Copy-and-Delete" fallback to ensure
  /// the move succeeds regardless of filesystem boundaries.
  static Future<File> safeMove(final String sourcePath, final String destinationPath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      DiagnosticsLog.error('FileSystemUtils', 'Source file does not exist for move: $sourcePath');
      throw FileSystemException('Source file does not exist', sourcePath);
    }

    // Ensure the destination directory exists
    final destFile = File(destinationPath);
    final destDir = destFile.parent;
    if (!await destDir.exists()) {
      DiagnosticsLog.info('FileSystemUtils', 'Creating destination directory: ${destDir.path}');
      await destDir.create(recursive: true);
      // Small delay to ensure OS file system catch up (prevents rare race conditions)
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    try {
      // 1. Try renaming first (atomic and fast if on the same partition)
      DiagnosticsLog.info('FileSystemUtils', 'Attempting atomic rename: $sourcePath -> $destinationPath');
      return await source.rename(destinationPath);
    } on FileSystemException catch (e) {
      // 2. If rename fails (common on iOS/Android across partitions),
      // fallback to copy-and-delete.
      DiagnosticsLog.warn('FileSystemUtils', 'Rename failed ($e), falling back to copy/delete strategy');
      
      try {
        // Perform the copy
        final copied = await source.copy(destinationPath);
        
        // Verify the copy exists and has bytes before deleting the original
        if (await copied.exists() && (await copied.length()) > 0) {
          await source.delete();
          DiagnosticsLog.info('FileSystemUtils', 'Copy-and-delete successful');
          return copied;
        } else {
          DiagnosticsLog.error('FileSystemUtils', 'Copy failed or resulted in an empty file: $destinationPath');
          throw FileSystemException(
            'Copy failed or resulted in an empty file',
            destinationPath,
          );
        }
      } catch (copyErr) {
        DiagnosticsLog.error('FileSystemUtils', 'Manual copy-delete fallback failed: $copyErr');
        rethrow;
      }
    }
  }

  /// Recursively delete empty parent directories...
  static Future<void> pruneEmptyParents(
    final String filePath, {
    required final String stopDir,
  }) async {
    // ... (existing implementation)
  }

  /// Offloads a heavy file copy to a background isolate.
  static Future<void> copyFileBackground(final String source, final String target) async {
    await compute(_copyIsolate, _TransferArgs(source, target));
  }

  /// Offloads a file move to a background isolate (atomic rename or copy-delete).
  static Future<void> moveFileBackground(final String source, final String target) async {
    await compute(_moveIsolate, _TransferArgs(source, target));
  }

  /// Moves a file with real-time progress tracking.
  /// Falls back to copy-delete if rename fails.
  static Stream<double> moveFileWithProgress(final String sourcePath, final String targetPath) async* {
    final source = File(sourcePath);
    final target = File(targetPath);
    
    if (!await source.exists()) throw FileSystemException('Source missing', sourcePath);
    
    // Ensure target dir
    final targetDir = target.parent;
    if (!await targetDir.exists()) await targetDir.create(recursive: true);

    try {
      // Fast path: Atomic rename (0% -> 100% instantly)
      await source.rename(targetPath);
      yield 1.0;
    } on Object catch (_) {
      // Slow path: Partition crossing copy-delete
      final total = await source.length();
      var processed = 0;
      
      final sink = target.openWrite();
      final stream = source.openRead();
      
      await for (final chunk in stream) {
        sink.add(chunk);
        processed += chunk.length;
        yield processed / total;
      }
      
      await sink.flush();
      await sink.close();
      await source.delete();
    }
  }
}

class _TransferArgs {
  final String source;
  final String target;
  const _TransferArgs(this.source, this.target);
}

void _copyIsolate(final _TransferArgs args) {
  final s = File(args.source);
  if (s.existsSync()) {
    Directory(p.dirname(args.target)).createSync(recursive: true);
    s.copySync(args.target);
  }
}

void _moveIsolate(final _TransferArgs args) {
  final s = File(args.source);
  if (!s.existsSync()) return;
  Directory(p.dirname(args.target)).createSync(recursive: true);
  try {
    s.renameSync(args.target);
  } on Object catch (_) {
    s.copySync(args.target);
    s.deleteSync();
  }
}
