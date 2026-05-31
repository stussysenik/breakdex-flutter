import 'dart:io';
import 'package:path/path.dart' as p;

// Copy minimal dependencies to test the exact flow
void main() async {
  // Setup temp paths
  final rootDir = Directory.current.path;
  final docsPath = p.join(rootDir, 'mock_documents');
  final tmpPath = p.join(rootDir, 'mock_tmp');
  
  await Directory(docsPath).create(recursive: true);
  await Directory(tmpPath).create(recursive: true);
  
  final sourceFile = File(p.join(tmpPath, 'picked_video.mp4'));
  await sourceFile.writeAsString('fake video content');
  
  print('Source exists: ${await sourceFile.exists()}');
  
  // Try to simulate moveToSemanticPath
  final category = 'Power moves';
  final moveName = 'Yessir';
  final hash = '123456';
  
  // Mock VideoPathResolver logic
  String getSafeCategory(String c) {
    final sanitized = c.replaceAll('/', '-').replaceAll(':', '-').trim();
    if (sanitized.length <= 1) return sanitized.toUpperCase();
    return sanitized[0].toUpperCase() + sanitized.substring(1).toLowerCase();
  }
  
  final safeCat = getSafeCategory(category);
  final safeName = moveName[0].toUpperCase() + moveName.substring(1).toLowerCase();
  
  final newRelative = p.join('Moves', safeCat, safeName, '$hash.mp4');
  final newAbs = p.join(docsPath, newRelative);
  
  print('New Abs: $newAbs');
  
  final newDir = Directory(p.dirname(newAbs));
  if (!await newDir.exists()) {
    await newDir.create(recursive: true);
  }
  
  // Simulate safeMove
  try {
    print('Attempting rename...');
    await sourceFile.rename(newAbs);
  } catch (e) {
    print('Rename failed: $e, falling back to copy/delete');
    final copied = await sourceFile.copy(newAbs);
    if (await copied.exists() && (await copied.length()) > 0) {
      await sourceFile.delete();
      print('Copy successful');
    } else {
      print('Copy failed');
      exit(1);
    }
  }
  
  final destExists = await File(newAbs).exists();
  print('Destination exists: $destExists');
  
  if (!destExists) {
    exit(1);
  }
  
  print('Success');
  exit(0);
}
