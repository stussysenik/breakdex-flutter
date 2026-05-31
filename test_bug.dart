import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  final tmpPath = p.join(Directory.current.path, 'mock_tmp');
  await Directory(tmpPath).create(recursive: true);
  final sourceFile = File(p.join(tmpPath, 'non_existent_video.mp4'));
  
  Future<String> moveToSemanticPath(String currentRelativePath) async {
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
  } catch (e) {
    print('SUCCESS: Error correctly rethrown! The DB will no longer store invalid temporary paths. $e');
    exit(0);
  }
  
  print('Unexpected success');
  exit(1);
}
