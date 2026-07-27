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

/// Computes and verifies SHA-256 content hashes for video files.
class AssetHashService {
  static const _chunkSize = 4 * 1024 * 1024;

  /// Compute the SHA-256 hex digest of a file in a background isolate.
  Future<String> computeHash(final String filePath) async {
    return compute(_computeHashIsolate, filePath);
  }

  /// Streams 0.0 to 1.0 progress as the file is hashed.
  /// Final event is the hash string itself.
  Stream<dynamic> computeHashWithProgress(final String filePath) async* {
    final receivePort = ReceivePort();
    await Isolate.spawn(_computeHashWithProgressIsolate, _HashArgs(filePath, receivePort.sendPort));

    await for (final message in receivePort) {
      if (message is HashPercent) {
        yield message.percent;
      } else if (message is HashValue) {
        yield message.hash;
        receivePort.close();
        break;
      }
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
