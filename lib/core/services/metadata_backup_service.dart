import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart';
import '../sync/cloud_provider.dart';
import 'stats_export_service.dart';

/// Auto-activation of the *scheduled* Drive backup. Default OFF to match the
/// overnight-wave discipline (device behavior stays byte-identical until the
/// owner's Phase M soak); the **manual** trigger ([MetadataBackupService.backupNow])
/// works regardless of this flag. Flip via `--dart-define=METADATA_DRIVE_BACKUP=true`
/// or here after soak. See openspec migrate-canonical-backend-to-appwrite task 5.3.
const bool kMetadataDriveBackupEnabled = bool.fromEnvironment(
  'METADATA_DRIVE_BACKUP',
  defaultValue: false,
);

/// Outcome of a metadata backup attempt.
class BackupResult {
  const BackupResult({
    required this.status,
    this.remotePath,
    this.bytes = 0,
    this.records = 0,
    this.reason,
  });

  final BackupStatus status;
  final String? remotePath;
  final int bytes;
  final int records;

  /// Human-readable reason when [status] is [BackupStatus.skipped] or
  /// [BackupStatus.failed].
  final String? reason;

  bool get uploaded => status == BackupStatus.uploaded;
}

enum BackupStatus { uploaded, skipped, failed }

/// Periodic + manual JSON metadata backup to the user's Drive (task 5.3).
///
/// The data-ownership safety net: the full tombstone-inclusive export
/// ([StatsExportService.generateJsonExport], schema v10) is written to a temp
/// file and pushed to `Breakdex/backups/` on the user's own Drive quota. It is
/// restorable via [StatsExportService.importFromJson]. Videos are **not** copied
/// here — they live on Drive already; this is the metadata safety net only.
class MetadataBackupService {
  MetadataBackupService(
    this.db,
    this.prefs,
    this.provider, {
    final Future<Directory> Function()? scratchDir,
  }) : _scratchDir = scratchDir ?? getTemporaryDirectory;

  final AppDatabase db;
  final SharedPreferences prefs;

  /// The sink — the user's Drive (`gdrive`) provider.
  final CloudProvider provider;

  final Future<Directory> Function() _scratchDir;

  /// Remote directory on the user's Drive that holds metadata snapshots.
  static const backupDir = 'Breakdex/backups';

  /// Default cadence for [backupIfStale].
  static const defaultInterval = Duration(hours: 24);

  static const _lastBackupKey = 'metadata_backup_last_at';

  /// When the last successful backup completed, or null if never.
  DateTime? get lastBackupAt {
    final raw = prefs.getString(_lastBackupKey);
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  /// Runs a backup now: export → temp file → upload → record timestamp.
  ///
  /// Skips (does not throw) when the provider is not authenticated — a backup
  /// is a best-effort safety net, never a blocker.
  Future<BackupResult> backupNow() async {
    if (!await provider.isAuthenticated) {
      return const BackupResult(
        status: BackupStatus.skipped,
        reason: 'provider not authenticated',
      );
    }

    final export = await StatsExportService.generateJsonExport(db, prefs);
    final dir = await _scratchDir();
    final file = File(p.join(dir.path, StatsExportService.exportFilename));
    await file.writeAsString(export.json, flush: true);

    try {
      final remotePath = '$backupDir/${StatsExportService.exportFilename}';
      final remote = await provider.upload(
        localPath: file.path,
        remotePath: remotePath,
      );
      await prefs.setString(
        _lastBackupKey,
        DateTime.now().toIso8601String(),
      );
      return BackupResult(
        status: BackupStatus.uploaded,
        remotePath: remote.remotePath,
        bytes: remote.sizeBytes,
        records: export.totalRecords,
      );
    } on Object catch (e) {
      return BackupResult(status: BackupStatus.failed, reason: '$e');
    } finally {
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }

  /// Runs a backup only if the last one is older than [interval] (or never ran).
  /// This is the "scheduled" trigger — call it on app resume / launch.
  Future<BackupResult> backupIfStale({
    final Duration interval = defaultInterval,
  }) async {
    final last = lastBackupAt;
    if (last != null && DateTime.now().difference(last) < interval) {
      return const BackupResult(
        status: BackupStatus.skipped,
        reason: 'last backup still fresh',
      );
    }
    return backupNow();
  }
}

/// Fires the scheduled metadata backup on launch and app-pause, mirroring
/// [AutomaticDatabaseBackupController]. No-ops unless [kMetadataDriveBackupEnabled]
/// is flipped on (post-soak) and off-web (temp-file APIs are native-only).
///
/// The service is resolved lazily each run because the gdrive provider is only
/// available once sync is configured + authenticated; [resolve] returns null
/// until then, and the run is a silent no-op.
class MetadataBackupController with WidgetsBindingObserver {
  MetadataBackupController({
    required final Future<MetadataBackupService?> Function() resolve,
  }) : _resolve = resolve;

  final Future<MetadataBackupService?> Function() _resolve;
  Future<void>? _running;

  void start() {
    if (kIsWeb || !kMetadataDriveBackupEnabled) return;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_run());
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _running;
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached) {
      return;
    }
    unawaited(_run());
  }

  Future<void> _run() async {
    final running = _running;
    if (running != null) return running;

    final future = () async {
      final service = await _resolve();
      if (service == null) return;
      await service.backupIfStale();
    }();
    _running = future;
    try {
      await future;
    } finally {
      if (identical(_running, future)) {
        _running = null;
      }
    }
  }
}
