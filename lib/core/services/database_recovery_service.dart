// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import 'dart:async';
import '../platform/io.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import 'app_storage_paths.dart';

class DatabaseRecoveryService {
  DatabaseRecoveryService({
    final Future<Directory> Function()? documentsDirectory,
    final DateTime Function()? now,
  }) : _documentsDirectory =
           documentsDirectory ?? AppStoragePaths.documentsDirectory,
       _now = now ?? DateTime.now;

  static const databaseFilename = 'breakdex.db';
  static const backupFilenamePrefix = 'breakdex_backup_';
  static const corruptFilenamePrefix = 'breakdex_corrupt_';
  static const databaseFilenameSuffix = '.db';
  static const rollingBackupInterval = Duration(hours: 6);
  static const maxBackupFiles = 5;

  final Future<Directory> Function() _documentsDirectory;
  final DateTime Function() _now;

  Future<File> primaryDatabaseFile() async {
    final directory = await _documentsDirectory();
    return File(p.join(directory.path, databaseFilename));
  }

  Future<bool> restoreLatestBackupIfPrimaryUnavailable() async {
    final primary = await primaryDatabaseFile();
    if (await _isUsableFile(primary)) return false;
    return _restoreMostRecentBackup();
  }

  Future<Directory> _backupsDirectory() async {
    final docs = await _documentsDirectory();
    final dir = Directory(p.join(docs.path, '.backups'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<List<File>> listBackupFilesNewestFirst() async {
    final directory = await _backupsDirectory();
    if (!await directory.exists()) return const [];

    final backupFiles = <File>[];
    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      final basename = p.basename(entity.path);
      if (!basename.startsWith(backupFilenamePrefix) ||
          !basename.endsWith(databaseFilenameSuffix)) {
        continue;
      }
      if (!await _isUsableFile(entity)) continue;
      backupFiles.add(entity);
    }

    backupFiles.sort((final a, final b) => _sortKeyFor(b).compareTo(_sortKeyFor(a)));
    return backupFiles;
  }

  Future<void> replacePrimaryWithBackup(final File backupFile) async {
    if (!await _isUsableFile(backupFile)) {
      throw StateError('Backup file is not readable.');
    }

    final primary = await primaryDatabaseFile();
    if (await primary.exists()) {
      await primary.delete();
    }
    await backupFile.copy(primary.path);
  }

  Future<void> deletePrimaryDatabase() async {
    final primary = await primaryDatabaseFile();
    if (await primary.exists()) {
      await primary.delete();
    }
  }

  Future<void> stashPrimaryAsCorrupt() async {
    final primary = await primaryDatabaseFile();
    if (!await primary.exists()) return;

    if (!await _isUsableFile(primary)) {
      await primary.delete();
      return;
    }

    final directory = await _backupsDirectory();
    final corruptFile = File(
      p.join(
        directory.path,
        '$corruptFilenamePrefix${_now().millisecondsSinceEpoch}$databaseFilenameSuffix',
      ),
    );
    await primary.rename(corruptFile.path);
  }

  Future<bool> createRollingBackupIfDue({final bool force = false}) async {
    final primary = await primaryDatabaseFile();
    if (!await _isUsableFile(primary)) return false;

    final backups = await listBackupFilesNewestFirst();
    final latestBackup = backups.isEmpty ? null : backups.first;
    if (!force && latestBackup != null) {
      final latestBackupModified = await latestBackup.lastModified();
      final primaryModified = await primary.lastModified();
      final backupAge = _now().difference(latestBackupModified);
      final primaryChangedSinceBackup = primaryModified.isAfter(
        latestBackupModified,
      );
      if (backupAge < rollingBackupInterval && !primaryChangedSinceBackup) {
        return false;
      }
    }

    final directory = await _backupsDirectory();
    final backupFile = File(
      p.join(
        directory.path,
        '$backupFilenamePrefix${_now().millisecondsSinceEpoch}$databaseFilenameSuffix',
      ),
    );
    await primary.copy(backupFile.path);
    await _pruneOldBackups();
    return true;
  }

  Future<bool> _restoreMostRecentBackup() async {
    final backups = await listBackupFilesNewestFirst();
    final backup = backups.isEmpty ? null : backups.first;
    if (backup == null) return false;
    await replacePrimaryWithBackup(backup);
    return true;
  }

  int _sortKeyFor(final File file) {
    final basename = p.basenameWithoutExtension(file.path);
    final rawValue = basename.substring(backupFilenamePrefix.length);
    return int.tryParse(rawValue) ?? 0;
  }

  Future<bool> _isUsableFile(final File file) async {
    if (!await file.exists()) return false;
    return await file.length() > 0;
  }

  Future<void> _pruneOldBackups() async {
    final backups = await listBackupFilesNewestFirst();
    for (final backup in backups.skip(maxBackupFiles)) {
      await backup.delete();
    }
  }
}

class AutomaticDatabaseBackupController with WidgetsBindingObserver {
  AutomaticDatabaseBackupController({required final DatabaseRecoveryService service})
    : _service = service;

  final DatabaseRecoveryService _service;
  Future<void>? _runningBackup;

  void start() {
    // Web has no on-disk SQLite file to back up (the DB lives in OPFS); the
    // rolling backup calls native file APIs that throw. No-op visibly on web.
    if (kIsWeb) return;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_backupIfNeeded());
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _runningBackup;
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached) {
      return;
    }
    unawaited(_backupIfNeeded(force: state == AppLifecycleState.detached));
  }

  Future<void> _backupIfNeeded({final bool force = false}) async {
    final runningBackup = _runningBackup;
    if (runningBackup != null) return runningBackup;

    final future = _service.createRollingBackupIfDue(force: force).then((_) {});
    _runningBackup = future;
    try {
      await future;
    } finally {
      if (identical(_runningBackup, future)) {
        _runningBackup = null;
      }
    }
  }
}
