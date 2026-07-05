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
import 'core/services/video_storage_gate.dart';
import 'core/services/fsrs_migration_service.dart';
import 'core/services/managed_album_reconciliation_service.dart';
import 'core/services/provenance_journal_service.dart';
import 'core/services/settings_service.dart';
import 'core/sync/asset_hash_service.dart';
import 'core/sync/legacy_asset_migration.dart';
import 'core/sync/video_reliability_runtime.dart';
import 'core/utils/diagnostics.dart';
import 'core/services/storage_janitor.dart';
import 'core/services/boot_coordinator.dart';

final _rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Create a timestamped backup of the database file before migrations run.
Future<void> _backupDatabaseIfNeeded(
  final SharedPreferences prefs,
  final DatabaseRecoveryService recoveryService,
  final ProvenanceJournalService provenanceJournal,
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
  } on Object catch (error) {
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
  }
}

/// Open database with crash recovery.
Future<AppDatabase> _openDatabaseSafely(
  final DatabaseRecoveryService recoveryService,
  final ProvenanceJournalService provenanceJournal,
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
  } on Object catch (e) {
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
        } on Object catch (backupError) {
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
    } on Object catch (_) {}
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
Future<void> _runMigrations(final AppDatabase db, final SharedPreferences prefs) async {
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
  } on Object catch (e) {
    debugPrint('Post-frame migration failed: $e');
  }
}

void main() async {
  final stopwatch = Stopwatch()..start();
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

  // 1. Initialize synchronous-ish core dependencies first
  final sharedPrefs = await SharedPreferences.getInstance();
  final provenanceJournal = ProvenanceJournalService();
  final recoveryService = DatabaseRecoveryService();

  // 2. Open database with recovery logic
  final restoredPrimary = await recoveryService
      .restoreLatestBackupIfPrimaryUnavailable();
  
  await _backupDatabaseIfNeeded(sharedPrefs, recoveryService, provenanceJournal);
  final db = await _openDatabaseSafely(recoveryService, provenanceJournal);

  // 3. Create THE container with all final instances
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      databaseProvider.overrideWithValue(db),
      databaseRecoveryServiceProvider.overrideWithValue(recoveryService),
      provenanceJournalServiceProvider.overrideWithValue(provenanceJournal),
    ],
  );

  final boot = container.read(bootCoordinatorProvider.notifier);
  boot.completeGate(BootGate.database);
  boot.completeGate(BootGate.recovery, detail: restoredPrimary ? 'restored' : 'skipped');
  boot.completeGate(BootGate.preferences);

  // 4. Initialize async plugins in parallel
  unawaited(Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      .then((_) => boot.completeGate(BootGate.firebase)));
  unawaited(VideoPathResolver.initialize()
      .then((_) => boot.completeGate(BootGate.videoResolver)));
  unawaited(VideoStorageGate.initialize()
      .then((_) => boot.completeGate(BootGate.storageGate)));

  await AutomationFixtureService().seedIfRequested(db, prefs: sharedPrefs);

  // --- Global error handlers ---
  FlutterError.onError = (final details) {
    FlutterError.presentError(details);
    unawaited(
      provenanceJournal.log(
        scope: 'crash',
        eventType: 'flutter_error',
        status: 'captured',
        message: details.exceptionAsString(),
      ),
    );
  };
  PlatformDispatcher.instance.onError = (final error, final stack) {
    unawaited(
      provenanceJournal.log(
        scope: 'crash',
        eventType: 'platform_error',
        status: 'captured',
        message: '$error',
      ),
    );
    return true;
  };

  // Global error widget for production resilience
  ErrorWidget.builder = (final details) => Material(
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
    UncontrolledProviderScope(
      container: container,
      child: const BreakdexApp(),
    ),
  );

  // Run deferred startup work after the first frame renders
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Run FSRS migrations
    try {
      await _runMigrations(db, sharedPrefs);
      boot.completeGate(BootGate.migrations);
    } on Object catch (e) {
      debugPrint('FSRS migration failed: $e');
    }

    // Reconcile Filesystem with Database Truth (The Janitor)
    try {
      await container.read(storageJanitorProvider).reconcile();
      boot.completeGate(BootGate.healing);
    } on Object catch (e) {
      debugPrint('Storage reconciliation failed: $e');
    }

    // Migrate existing videos into the content-addressable manifest.
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
      boot.completeGate(BootGate.legacyMigration);
    } on Object catch (e) {
      debugPrint('Legacy asset migration failed: $e');
    }
    
    DiagnosticsLog.info('Boot', 'App startup completed in ${stopwatch.elapsedMilliseconds}ms');
    stopwatch.stop();
  });
}

class BreakdexApp extends ConsumerWidget {
  const BreakdexApp({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Activate manifest sync — watches all DAOs and uploads manifest.json
    ref.watch(manifestSyncTriggerProvider);

    // Auto-retry asset sync when connectivity is restored.
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
      builder: (final context, final child) {
        return _BootGateOverlay(
          child: _StartupReliabilityToastGate(child: child),
        );
      },
    );
  }
}

/// Overlay that shows a loading indicator until the core boot gates are cleared.
///
/// While the splash is visible it ticks ~12x/second so the progress bar
/// interpolates smoothly toward the device's historical time-to-ready (rather
/// than freezing between discrete gate completions) and shows a live ETA.
class _BootGateOverlay extends ConsumerStatefulWidget {
  const _BootGateOverlay({required this.child});
  final Widget child;

  @override
  ConsumerState<_BootGateOverlay> createState() => _BootGateOverlayState();
}

class _BootGateOverlayState extends ConsumerState<_BootGateOverlay> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      if (ref.read(bootCoordinatorProvider).isReadyForUI) {
        _ticker?.cancel();
        _ticker = null;
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final boot = ref.watch(bootCoordinatorProvider);

    // Once core gates are cleared, we show the app content.
    // Post-frame background work (migrations, etc.) happens while interactive.
    if (boot.isReadyForUI) {
      return Stack(
        children: [
          widget.child,
          if (!boot.isComplete)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: boot.postFrameProgress,
                  backgroundColor: Colors.transparent,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  minHeight: 2,
                ),
              ),
            ),
        ],
      );
    }

    // Determinate splash while core gates are clearing — real progress + ETA.
    final elapsed = DateTime.now().difference(boot.startTime);
    final progress = boot.interpolatedProgress(elapsed);
    final eta = boot.eta(elapsed);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: progress > 0 ? progress : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${(progress * 100).round()}%',
              style: theme.textTheme.bodySmall,
            ),
            if (boot.currentTask != null) ...[
              const SizedBox(height: 4),
              Text(
                boot.currentTask!,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (eta != null && eta.inMilliseconds > 250) ...[
              const SizedBox(height: 4),
              Text(
                '~${eta.inSeconds + 1}s',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              ),
            ],
          ],
        ),
      ),
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
  Widget build(final BuildContext context) {
    ref.listen(videoReliabilityReportProvider, (_, final next) {
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

    ref.listen(managedAlbumLifecycleReportProvider, (_, final next) {
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

  void _queueStartupSnackBar(final String message) {
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
