import 'package:breakdex/core/platform/io.dart';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Message sent back from the hash isolate.
sealed class HashProgress {
  const HashProgress();
}
class HashValue extends HashProgress {
  final String hash;
  const HashValue(this.hash);
}
class HashPercent extends HashProgress {
  final double percent;
  const HashPercent(this.percent);
}

/// The hash isolate ended without producing a value.
///
/// Not a hashing bug: it means the isolate itself died — typically [path] being
/// missing or unreadable, which kills `lengthSync`/`openSync` before a single
/// progress message can be sent.
class HashIsolateFailure implements Exception {
  const HashIsolateFailure(this.path, this.detail);

  final String path;

  /// The isolate's own error text, or a statement that it exited silently.
  final String detail;

  @override
  String toString() => 'HashIsolateFailure($path): $detail';
}

/// Computes and verifies SHA-256 content hashes for video files.
class AssetHashService {
  static const _chunkSize = 4 * 1024 * 1024;

  /// Compute the SHA-256 hex digest of a file in a background isolate.
  Future<String> computeHash(final String filePath) async {
    return compute(_computeHashIsolate, filePath);
  }

  /// Streams 0.0 to 1.0 progress as the file is hashed.
  /// Final event is the hash string itself.
  ///
  /// Death of the isolate is a stream error, never silence. `onError` and
  /// `onExit` are multiplexed onto the same port as the data, so the loop reads
  /// three message shapes and one of them always arrives: [HashProgress] from
  /// the work, a `List` of `[error, stackTrace]` from an uncaught throw, or
  /// `null` from exit. Without the exit port an isolate that dies before its
  /// first send — a missing or unreadable [filePath] is the common case — leaves
  /// this `await for` waiting forever, which surfaces as a progress spinner that
  /// neither resolves nor errors.
  Stream<dynamic> computeHashWithProgress(final String filePath) async* {
    final port = ReceivePort();
    try {
      await Isolate.spawn(
        _computeHashWithProgressIsolate,
        _HashArgs(filePath, port.sendPort),
        onError: port.sendPort,
        onExit: port.sendPort,
      );

      await for (final message in port) {
        switch (message) {
          case HashPercent(:final percent):
            yield percent;
          case HashValue(:final hash):
            yield hash;
            return;
          // `onError` sends [error, stackTrace], both already stringified by
          // the runtime — an uncaught throw inside the isolate.
          case final List<Object?> failure:
            throw HashIsolateFailure(filePath, '${failure.firstOrNull}');
          // `onExit` sends null. Reaching it means the isolate ended without
          // yielding a hash; an error, if there was one, arrived first.
          case null:
            throw HashIsolateFailure(
              filePath,
              'isolate exited before producing a hash',
            );
        }
      }
    } finally {
      port.close();
    }
  }

  /// Verify that a file's content matches the expected hash.
  Future<bool> verifyHash(final String filePath, final String expectedHash) async {
    try {
      final actual = await computeHash(filePath);
      return actual == expectedHash;
    } on Object catch (_) {
      return false;
    }
  }

  static String _computeHashIsolate(final String filePath) {
    final file = File(filePath);
    final output = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);

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

  static void _computeHashWithProgressIsolate(final _HashArgs args) {
    final file = File(args.filePath);
    final size = file.lengthSync();
    final output = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);

    final raf = file.openSync();
    var processed = 0;
    try {
      final buffer = Uint8List(_chunkSize);
      int bytesRead;
      do {
        bytesRead = raf.readIntoSync(buffer);
        if (bytesRead > 0) {
          processed += bytesRead;
          input.add(bytesRead == buffer.length
              ? buffer
              : Uint8List.sublistView(buffer, 0, bytesRead));
          
          args.sendPort.send(HashPercent(processed / size));
        }
      } while (bytesRead == _chunkSize);
    } finally {
      raf.closeSync();
    }

    input.close();
    args.sendPort.send(HashValue(output.events.single.toString()));
  }
}

class _HashArgs {
  final String filePath;
  final SendPort sendPort;
  const _HashArgs(this.filePath, this.sendPort);
}

class AccumulatorSink<T> implements Sink<T> {
  final List<T> events = [];
  @override
  void add(final T event) => events.add(event);
  @override
  void close() {}
}
