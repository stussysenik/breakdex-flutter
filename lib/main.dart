import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'core/database/database.dart';
import 'core/design/theme.dart';
import 'core/navigation/app_router.dart';
import 'core/providers.dart';
import 'core/services/automation_fixture_service.dart';
import 'core/services/fsrs_migration_service.dart';
import 'core/services/settings_service.dart';

/// Create a timestamped backup of the database file before migrations run.
/// This is a safety net — if a migration corrupts data, the user can recover
/// from the backup file in the documents directory.
Future<void> _backupDatabaseIfNeeded(SharedPreferences prefs) async {
  final lastBackupSchema = prefs.getInt('last_backup_schema') ?? 0;
  const currentSchema = 9;

  if (lastBackupSchema < currentSchema) {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dir.path, 'breakdex.db'));
      if (await dbFile.exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final backupPath = p.join(dir.path, 'breakdex_backup_$timestamp.db');
        await dbFile.copy(backupPath);
      }
      await prefs.setInt('last_backup_schema', currentSchema);
    } catch (_) {
      // Backup failure is non-fatal — don't block app launch
    }
  }
}

/// Open database with crash recovery. If the DB smoke test throws
/// (e.g. corrupted file in release mode), delete the DB and start fresh.
/// This prevents infinite crash loops on physical devices.
///
/// **Note:** Migrations are intentionally NOT run here — they happen after
/// the first frame via [_runMigrations] to avoid iOS Jetsam kills during
/// the critical launch window.
Future<AppDatabase> _openDatabaseSafely() async {
  try {
    final db = AppDatabase();
    // Smoke-test: lightweight count query verifies the DB is readable
    // without loading any rows into memory.
    await db.movesDao.count();
    return db;
  } catch (e) {
    debugPrint('DB init failed ($e) — creating fresh database');
    // Attempt to delete the corrupted file so the next open succeeds
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dir.path, 'breakdex.db'));
      if (await dbFile.exists()) await dbFile.delete();
    } catch (_) {}
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

  // --- Global error handlers (catch crashes that would kill release builds) ---
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    if (!kReleaseMode && details.stack != null) {
      debugPrintStack(stackTrace: details.stack);
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught platform error: $error\n$stack');
    return true; // Prevent crash — error is logged but app stays alive
  };

  final prefs = await SharedPreferences.getInstance();

  // Backup database before migration (safety net for schema changes)
  await _backupDatabaseIfNeeded(prefs);

  // Open DB with crash recovery — prevents infinite crash loop on device.
  // Migrations are deferred to after the first frame (see addPostFrameCallback below).
  final db = await _openDatabaseSafely();
  await AutomationFixtureService().seedIfRequested(db, prefs: prefs);

  // Global error widget for production resilience
  ErrorWidget.builder = (details) => Material(
    color: Colors.transparent,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Something went wrong',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
      ],
      child: const BreakdexApp(),
    ),
  );

  // Run FSRS migrations after the first frame renders — keeps the launch
  // window lightweight so iOS doesn't Jetsam-kill us for memory/CPU pressure.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await _runMigrations(db, prefs);
  });
}

class BreakdexApp extends ConsumerWidget {
  const BreakdexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSetting = ref.watch(themeSettingProvider);
    final viewingMode = ref.watch(viewingModeProvider);
    final fontFamily = ref.watch(fontFamilyProvider);
    final accent = ref.watch(accentColorProvider);

    return MaterialApp.router(
      title: 'Breakdex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(
        family: fontFamily,
        accent: accent,
        viewingMode: viewingMode,
      ),
      darkTheme: AppTheme.dark(
        family: fontFamily,
        accent: accent,
        viewingMode: viewingMode,
      ),
      themeMode: themeSetting.themeMode,
      routerConfig: appRouter,
    );
  }
}
