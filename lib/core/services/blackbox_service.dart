// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import 'package:breakdex/core/platform/io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:breakdex/core/services/app_storage_paths.dart';

/// A robust, append-only safety log for all critical data operations.
///
/// This "Blackbox" provides a recovery trail independent of the SQLite database.
/// If the main database is lost or corrupted, the Blackbox log can be used
/// to reconstruct the state of the library.
class BlackboxService {
  static const _filename = 'blackbox.log';

  Future<File> get _file async {
    final dir = await AppStoragePaths.documentsDirectory();
    return File(p.join(dir.path, _filename));
  }

  /// Log a critical operation. Format: `[timestamp] action | entityType | entityId | dataJson`
  Future<void> log(final String action, final String entityType, final String entityId, [final Map<String, dynamic>? data]) async {
    try {
      final file = await _file;
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final dataStr = data != null ? ' | ${data.toString()}' : '';
      final entry = '[$timestamp] $action | $entityType | $entityId$dataStr\n';
      
      await file.writeAsString(entry, mode: FileMode.append, flush: true);
    } on Object catch (e) {
      // Safety log failure should not crash the app, but we print it
      debugPrint('[Blackbox] Logging failed: $e');
    }
  }

  Future<List<String>> readRecent(final int lines) async {
    final file = await _file;
    if (!await file.exists()) return [];
    final content = await file.readAsLines();
    if (content.length <= lines) return content;
    return content.sublist(content.length - lines);
  }

  Future<void> clear() async {
    final file = await _file;
    if (await file.exists()) {
      await file.delete();
    }
  }
}
