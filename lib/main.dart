import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/database/database.dart';
import 'core/design/theme.dart';
import 'core/navigation/app_router.dart';
import 'core/providers.dart';
import 'core/services/automation_fixture_service.dart';
import 'core/services/database_recovery_service.dart';
import 'core/services/video_path_resolver.dart';
import 'core/services/canonical_folder_service.dart';
import 'core/services/video_storage_gate.dart';
import 'core/services/fsrs_migration_service.dart';
import 'core/services/managed_album_reconciliation_service.dart';
import 'core/services/provenance_journal_service.dart';
import 'core/services/settings_service.dart';
import 'core/sync/asset_hash_service.dart';
import 'core/sync/legacy_asset_migration.dart';
import 'core/sync/video_reliability_runtime.dart';
import 'core/utils/diagnostics.dart';

final _rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Create a timestamped backup of the database file before migrations run.
/// This is a safety net — if a migration corrupts data, the user can recover
/// from the backup file in the documents directory.
Future<void> _backupDatabaseIfNeeded(
  SharedPreferences prefs,
  DatabaseRecoveryService recoveryService,
  ProvenanceJournalService provenanceJournal,
) async {
  final lastBackupSchema = prefs.getInt('last_backup_schema') ?? 0;
  const currentSchema = 19;

  try {
    final createdBackup = await recoveryService.createRollingBackupIfDue(
      force: lastBackupSchema < currentSchema,
    );
    await provenanceJournal.log(
      scope: 'database_recovery',
      eventType: createdBackup ? 'backup_created' : 'backup_skipped',
      status: createdBackup ? 'created' : 'skipped',
      entityType: 'database',
      entityId: DatabaseRecoveryService.databaseFilename,
      message: createdBackup
          ? 'Rolling database backup created.'
          : 'Rolling database backup not needed.',
    );
    if (lastBackupSchema < currentSchema) {
      await prefs.setInt('last_backup_schema', currentSchema);
    }
  } catch (error) {
    unawaited(
      provenanceJournal.log(
        scope: 'database_recovery',
        eventType: 'backup_failed',
        status: 'failed',
        entityType: 'database',
        entityId: DatabaseRecoveryService.databaseFilename,
        message: 'Rolling database backup failed: $error',
      ),
    );
    // Backup failure is non-fatal — don't block app launch
  }
}

/// Open database with crash recovery. If the DB smoke test throws
/// (e.g. corrupted file in release mode), delete the DB and start fresh.
/// This prevents infinite crash loops on physical devices.
///
/// **Note:** Migrations are intentionally NOT run here — they happen after
/// the first frame via [_runMigrations] to avoid iOS Jetsam kills during
/// the critical launch window.
Future<AppDatabase> _openDatabaseSafely(
  DatabaseRecoveryService recoveryService,
  ProvenanceJournalService provenanceJournal,
) async {
  Future<AppDatabase> openAndSmokeTest() async {
    final db = AppDatabase();
    try {
      await db.movesDao.count();
      return db;
    } catch (_) {
      await db.close();
      rethrow;
    }
  }

  try {
    final db = await openAndSmokeTest();
    await provenanceJournal.log(
      scope: 'database_recovery',
      eventType: 'database_opened',
      status: 'ready',
      entityType: 'database',
      entityId: DatabaseRecoveryService.databaseFilename,
      message: 'Primary database opened successfully.',
    );
    return db;
  } catch (e) {
    debugPrint('DB init failed ($e) — attempting backup recovery');
    await provenanceJournal.log(
      scope: 'database_recovery',
      eventType: 'database_open_failed',
      status: 'failed',
      entityType: 'database',
      entityId: DatabaseRecoveryService.databaseFilename,
      message: 'Primary database open failed: $e',
    );
    try {
      await recoveryService.stashPrimaryAsCorrupt();
      final backups = await recoveryService.listBackupFilesNewestFirst();
      for (final backup in backups) {
        try {
          await provenanceJournal.log(
            scope: 'database_recovery',
            eventType: 'backup_restore_attempted',
            status: 'attempting',
            entityType: 'database_backup',
            entityId: p.basename(backup.path),
            message: 'Attempting database restore from backup.',
          );
          await recoveryService.replacePrimaryWithBackup(backup);
          final db = await openAndSmokeTest();
          await provenanceJournal.log(
            scope: 'database_recovery',
            eventType: 'backup_restored',
            status: 'restored',
            entityType: 'database_backup',
            entityId: p.basename(backup.path),
            message: 'Database restored from backup successfully.',
          );
          return db;
        } catch (backupError) {
          debugPrint(
            'Backup restore failed for ${p.basename(backup.path)}: $backupError',
          );
          await provenanceJournal.log(
            scope: 'database_recovery',
            eventType: 'backup_restore_failed',
            status: 'failed',
            entityType: 'database_backup',
            entityId: p.basename(backup.path),
            message: 'Database restore failed: $backupError',
          );
          await recoveryService.deletePrimaryDatabase();
        }
      }
    } catch (_) {}
    debugPrint('No readable backup found — creating fresh database');
    await provenanceJournal.log(
      scope: 'database_recovery',
      eventType: 'fresh_database_created',
      status: 'created',
      entityType: 'database',
      entityId: DatabaseRecoveryService.databaseFilename,
      message: 'No readable backup remained. Created a fresh database.',
    );
    return AppDatabase();
  }
}

/// Run FSRS data migrations after the first frame has rendered.
/// Deferring this work prevents iOS from killing the app for excessive
/// memory or main-thread stall during the startup watchdog window.
Future<void> _runMigrations(AppDatabase db, SharedPreferences prefs) async {
  try {
    await FsrsMigrationService.migrateIfNeeded(
      movesDao: db.movesDao,
      fsrsCardsDao: db.fsrsCardsDao,
      prefs: prefs,
    );

    await FsrsMigrationService.migrateComboCards(
      combosDao: db.combosDao,
      fsrsCardsDao: db.fsrsCardsDao,
      prefs: prefs,
    );

    await FsrsMigrationService.ensureIntegrity(
      movesDao: db.movesDao,
      fsrsCardsDao: db.fsrsCardsDao,
      combosDao: db.combosDao,
      prefs: prefs,
    );
  } catch (e) {
    debugPrint('Post-frame migration failed: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DiagnosticsLog.configure(
    threshold: kDebugMode ? LogLevel.trace : LogLevel.info,
  );
  DiagnosticsLog.setSubsystemThreshold('SwingDetector', LogLevel.trace);
  DiagnosticsLog.setSubsystemThreshold('Party', LogLevel.trace);
  DiagnosticsLog.setSubsystemThreshold('Party(Move)', LogLevel.trace);
  DiagnosticsLog.setSubsystemThreshold('Party(Combo)', LogLevel.trace);
  DiagnosticsLog.setSubsystemThreshold('ShakeDetector', LogLevel.trace);
  DiagnosticsLog.setSubsystemThreshold('VideoPathResolver', LogLevel.trace);
  DiagnosticsLog.setSubsystemThreshold('QuickVideoViewer', LogLevel.trace);
  DiagnosticsLog.info('Boot', 'Breakdex startup — diagnostics online');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final provenanceJournal = ProvenanceJournalService();

  // --- Global error handlers (catch crashes that would kill release builds) ---
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    unawaited(
      provenanceJournal.log(
        scope: 'crash',
        eventType: 'flutter_error',
        status: 'captured',
        message: details.exceptionAsString(),
      ),
    );
    if (!kReleaseMode && details.stack != null) {
      debugPrintStack(stackTrace: details.stack);
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught platform error: $error\n$stack');
    unawaited(
      provenanceJournal.log(
        scope: 'crash',
        eventType: 'platform_error',
        status: 'captured',
        message: '$error',
      ),
    );
    return true; // Prevent crash — error is logged but app stays alive
  };

  final prefs = await SharedPreferences.getInstance();
  final recoveryService = DatabaseRecoveryService();
  await provenanceJournal.log(
    scope: 'startup',
    eventType: 'app_boot',
    status: 'started',
    message: 'Application boot sequence started.',
  );
  final restoredPrimary = await recoveryService
      .restoreLatestBackupIfPrimaryUnavailable();
  await provenanceJournal.log(
    scope: 'database_recovery',
    eventType: restoredPrimary
        ? 'missing_primary_restored'
        : 'primary_present_or_no_backup',
    status: restoredPrimary ? 'restored' : 'skipped',
    entityType: 'database',
    entityId: DatabaseRecoveryService.databaseFilename,
    message: restoredPrimary
        ? 'Primary database was missing and restored from backup.'
        : 'Primary database already existed or no backup was available.',
  );

  // Cache the current documents directory path so VideoPathResolver can
  // convert between relative (DB) and absolute (file system) paths.
  await VideoPathResolver.initialize();

  // Initialize the storage gate so video write operations are validated
  // against the designated storage directories.
  await VideoStorageGate.initialize();

  // Backup database before migration (safety net for schema changes)
  await _backupDatabaseIfNeeded(prefs, recoveryService, provenanceJournal);

  // Open DB with crash recovery — prevents infinite crash loop on device.
  // Migrations are deferred to after the first frame (see addPostFrameCallback below).
  final db = await _openDatabaseSafely(recoveryService, provenanceJournal);
  await AutomationFixtureService().seedIfRequested(db, prefs: prefs);

  // Global error widget for production resilience
  ErrorWidget.builder = (details) => Material(
    color: Colors.transparent,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            details.exceptionAsString(),
            style: TextStyle(color: Colors.red[400], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        databaseRecoveryServiceProvider.overrideWithValue(recoveryService),
        provenanceJournalServiceProvider.overrideWithValue(provenanceJournal),
      ],
      child: const BreakdexApp(),
    ),
  );

  // Run deferred startup work after the first frame renders — keeps the
  // launch window lightweight so iOS doesn't Jetsam-kill us.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Delay 2 seconds to let Flutter finish painting the initial route
    // before heavy I/O competes with the raster thread.
    await Future<void>.delayed(const Duration(seconds: 2));

    // Run FSRS migrations (idempotent, gated by prefs)
    try {
      await _runMigrations(db, prefs);
    } catch (e) {
      debugPrint('FSRS migration failed: $e');
    }

    // Convert legacy absolute video paths and clean up filesystem.
    // Auto-cleanup is gated to once per 24h; DB healing is version-gated.
    try {
      await VideoPathHealer.healAll(db, prefs);
    } catch (e) {
      debugPrint('Video path healing failed: $e');
    }

    // Prune empty directories in canonical storage (cleanup from old nested hash layout).
    try {
      final canonicalFolder = CanonicalFolderService();
      await canonicalFolder.ensureInitialized();
      final removed = await canonicalFolder.pruneEmptyDirectories();
      DiagnosticsLog.info('Boot', 'canonical folder prune done — removed $removed empty dir(s)');
      final orphans = await canonicalFolder.scanOrphans();
      final diskOrphans = orphans.where((o) => o.isOrphan).length;
      final ledger = await canonicalFolder.readLedger();
      DiagnosticsLog.info('Boot',
          'canonical folder ledger — ${orphans.length} files on disk, '
          '${ledger.entries.length} in ledger, $diskOrphans disk orphan(s)');
    } catch (e) {
      debugPrint('Canonical folder init failed: $e');
    }

    // Migrate existing videos into the content-addressable manifest.
    // Idempotent — skips moves that already have a contentHash.
    // Runs one move at a time to avoid I/O saturation.
    try {
      final migration = LegacyAssetMigration(
        movesDao: db.movesDao,
        manifestDao: db.assetManifestDao,
        copiesDao: db.assetCopiesDao,
        hashService: AssetHashService(),
        db: db,
      );
      await for (final progress in migration.migrate()) {
        if (progress.currentMoveName != null) {
          debugPrint(
            'Legacy asset migration: ${progress.completed}/${progress.total}'
            ' — ${progress.currentMoveName}',
          );
        }
      }
    } catch (e) {
      debugPrint('Legacy asset migration failed: $e');
    }
  });
}

class BreakdexApp extends ConsumerWidget {
  const BreakdexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activate manifest sync — watches all DAOs and uploads manifest.json
    // to cloud storage on any metadata change (debounced 5s).
    ref.watch(manifestSyncTriggerProvider);

    // Auto-retry asset sync when connectivity is restored (offline → online).
    ref.watch(syncConnectivityTriggerProvider);

    // Reconcile managed Photos album copies with move archive state.
    ref.watch(managedAlbumLifecycleProvider);

    // Launch/runtime self-healing for recent cloud-backed videos.
    ref.watch(videoReliabilityLifecycleProvider);

    // Keep a rolling local DB backup so a regenerated sandbox can self-heal.
    ref.watch(automaticDatabaseBackupLifecycleProvider);

    final themeSetting = ref.watch(themeSettingProvider);
    final viewingMode = ref.watch(viewingModeProvider);
    final fontFamily = ref.watch(fontFamilyProvider);
    final accent = ref.watch(accentColorProvider);
    final stateColors = ref.watch(learningStateColorsProvider);

    return MaterialApp.router(
      title: 'Breakdex',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _rootScaffoldMessengerKey,
      theme: AppTheme.light(
        family: fontFamily,
        accent: accent,
        stateColors: stateColors,
        viewingMode: viewingMode,
      ),
      darkTheme: AppTheme.dark(
        family: fontFamily,
        accent: accent,
        stateColors: stateColors,
        viewingMode: viewingMode,
      ),
      themeMode: themeSetting.themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        return _StartupReliabilityToastGate(child: child);
      },
    );
  }
}

class _StartupReliabilityToastGate extends ConsumerStatefulWidget {
  const _StartupReliabilityToastGate({required this.child});

  final Widget? child;

  @override
  ConsumerState<_StartupReliabilityToastGate> createState() =>
      _StartupReliabilityToastGateState();
}

class _StartupReliabilityToastGateState
    extends ConsumerState<_StartupReliabilityToastGate> {
  int? _shownStartupReportEpoch;
  int? _shownManagedAlbumReportEpoch;

  @override
  Widget build(BuildContext context) {
    ref.listen(videoReliabilityReportProvider, (_, next) {
      final report = next.valueOrNull;
      if (report == null ||
          report.trigger != VideoReliabilityTrigger.startup ||
          !report.hasUserSignal) {
        return;
      }

      final epoch = report.completedAt.millisecondsSinceEpoch;
      if (_shownStartupReportEpoch == epoch) return;
      _shownStartupReportEpoch = epoch;
      _queueStartupSnackBar(report.snackBarMessage);
    });

    ref.listen(managedAlbumLifecycleReportProvider, (_, next) {
      final report = next.valueOrNull;
      if (report == null ||
          report.trigger != ManagedAlbumReconcileTrigger.startup ||
          !report.hasStartupSignal) {
        return;
      }

      final epoch = report.completedAt.millisecondsSinceEpoch;
      if (_shownManagedAlbumReportEpoch == epoch) return;
      _shownManagedAlbumReportEpoch = epoch;
      _queueStartupSnackBar(report.snackBarMessage);
    });

    return widget.child ?? const SizedBox.shrink();
  }

  void _queueStartupSnackBar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messenger = _rootScaffoldMessengerKey.currentState;
      if (messenger == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
}
