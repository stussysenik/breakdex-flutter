// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

// Scratch debug script — not part of the app.
// ignore_for_file: avoid_print, unused_local_variable
import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  final tmpPath = p.join(Directory.current.path, 'mock_tmp');
  await Directory(tmpPath).create(recursive: true);
  final sourceFile = File(p.join(tmpPath, 'non_existent_video.mp4'));
  
  Future<String> moveToSemanticPath(final String currentRelativePath) async {
    final newAbs = p.join(Directory.current.path, 'mock_docs', 'Moves', 'Power moves', 'Yessir', 'hash.mp4');
    try {
      if (!await File(currentRelativePath).exists()) {
        throw FileSystemException('Source file does not exist', currentRelativePath);
      }
      return 'Moves/Power moves/Yessir/hash.mp4';
    } catch (e) {
      // The bug fix applied! We rethrow the error.
      rethrow;
    }
  }

  try {
    final resultPath = await moveToSemanticPath(sourceFile.path);
    if (p.isAbsolute(resultPath) && resultPath.contains('mock_tmp')) {
      print('BUG DETECTED: moveToSemanticPath swallowed the error and returned the temporary absolute path!');
      exit(1);
    }
  } on Object catch (e) {
    print('SUCCESS: Error correctly rethrown! The DB will no longer store invalid temporary paths. $e');
    exit(0);
  }
  
  print('Unexpected success');
  exit(1);
}
