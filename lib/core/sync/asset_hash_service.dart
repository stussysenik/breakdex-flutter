import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Computes and verifies SHA-256 content hashes for video files.
///
/// All heavy computation runs in background isolates via [compute()] to avoid
/// blocking the UI thread. Files are read in 4 MB chunks to limit peak memory
/// usage — important for large training videos on memory-constrained devices.
class AssetHashService {
  /// Chunk size for reading files during hashing (4 MB).
  static const _chunkSize = 4 * 1024 * 1024;

  /// Compute the SHA-256 hex digest of a file in a background isolate.
  ///
  /// Returns the lowercase hex string (64 chars for SHA-256).
  Future<String> computeHash(String filePath) async {
    return compute(_computeHashIsolate, filePath);
  }

  /// Verify that a file's content matches the expected hash.
  Future<bool> verifyHash(String filePath, String expectedHash) async {
    try {
      final actual = await computeHash(filePath);
      return actual == expectedHash;
    } catch (_) {
      return false;
    }
  }

  /// Batch-hash all files in a list, emitting progress as (completed, total).
  ///
  /// Used during legacy migration and integrity verification. Each file is
  /// hashed sequentially to avoid saturating I/O bandwidth.
  Stream<(int completed, int total, String? currentHash)> hashAll(
    List<String> filePaths,
  ) async* {
    final total = filePaths.length;
    for (int i = 0; i < total; i++) {
      String? hash;
      try {
        hash = await computeHash(filePaths[i]);
      } catch (e) {
        debugPrint('Hash failed for ${filePaths[i]}: $e');
      }
      yield (i + 1, total, hash);
    }
  }

  /// Top-level function for [compute()] — runs in a background isolate.
  ///
  /// Reads the file in [_chunkSize] chunks and feeds them to a SHA-256
  /// digest incrementally. This keeps memory usage proportional to
  /// [_chunkSize] regardless of file size.
  static String _computeHashIsolate(String filePath) {
    final file = File(filePath);
    var output = AccumulatorSink<Digest>();
    var input = sha256.startChunkedConversion(output);

    final raf = file.openSync();
    try {
      final buffer = Uint8List(_chunkSize);
      int bytesRead;
      do {
        bytesRead = raf.readIntoSync(buffer);
        if (bytesRead > 0) {
          input.add(bytesRead == buffer.length
              ? buffer
              : Uint8List.sublistView(buffer, 0, bytesRead));
        }
      } while (bytesRead == _chunkSize);
    } finally {
      raf.closeSync();
    }

    input.close();
    return output.events.single.toString();
  }
}

/// Accumulates digest events from a chunked hash conversion.
///
/// The crypto package's [AccumulatorSink] collects all added values into
/// a list. For SHA-256, there's exactly one event (the final digest).
class AccumulatorSink<T> implements Sink<T> {
  final List<T> events = [];

  @override
  void add(T event) => events.add(event);

  @override
  void close() {}
}
