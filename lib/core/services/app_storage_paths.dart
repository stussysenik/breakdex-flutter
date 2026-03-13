import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract final class AppStoragePaths {
  static const MethodChannel _channel = MethodChannel('com.breakdex/app_paths');

  static Future<Directory> documentsDirectory() async {
    if (Platform.isIOS) {
      try {
        final path = await _channel.invokeMethod<String>('documentsDirectory');
        if (path != null && path.isNotEmpty) {
          final directory = Directory(path);
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          return directory;
        }
      } catch (_) {
        final directory = Directory(
          p.join(Directory.systemTemp.path, 'breakdex'),
        );
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return directory;
      }
    }

    return getApplicationDocumentsDirectory();
  }
}
