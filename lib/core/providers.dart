import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/database.dart';
import 'database/daos/moves_dao.dart';
import 'database/daos/combos_dao.dart';
import 'database/daos/reviews_dao.dart';
import 'database/daos/sync_dao.dart';
import 'database/daos/fsrs_cards_dao.dart';
import 'database/daos/decks_dao.dart';
import 'database/daos/sync_providers_dao.dart';
import 'data/repositories.dart';
import 'data/drift_repositories.dart';
import 'data/sync_aware_repositories.dart';
import 'design/colors.dart';
import 'design/typography.dart';
import 'models/reviewable_item.dart';
import 'services/auth_service.dart';
import 'services/settings_service.dart';
import 'services/video_service.dart';
import 'services/sync_service.dart';
import 'services/connectivity_service.dart';
import 'services/fsrs_service.dart';
import 'services/deck_service.dart';
import 'services/reviewable_naming_service.dart';
import 'services/scene_3d.dart';
import 'services/vision_ml.dart';
import 'models/sync_progress.dart';
import 'database/daos/asset_manifest_dao.dart';
import 'database/daos/asset_copies_dao.dart';
import 'database/daos/sync_operations_dao.dart';
import 'sync/asset_hash_service.dart';
import 'sync/asset_sync_engine.dart' as asset_sync;
import 'sync/background_sync_manager.dart';
import 'sync/cloud_provider.dart';
import 'sync/gdrive_setup_service.dart';
import 'sync/icloud_setup_service.dart';
import 'sync/integrity_verifier.dart';
import 'sync/legacy_asset_migration.dart';
import 'sync/network_policy.dart';
import 'sync/providers/gdrive_provider.dart';
import 'sync/providers/icloud_provider.dart';
import 'sync/safety_guard.dart';
import 'sync/tombstone_cleaner.dart';
import 'sync/manifest_serializer.dart';
import 'sync/manifest_sync_service.dart';
import 'sync/on_demand_downloader.dart';
import 'sync/space_manager.dart';
import 'sync/video_import_sync_hook.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// DAO providers (internal, used by repository implementations)
final movesDaoProvider = Provider<MovesDao>((ref) {
  return ref.watch(databaseProvider).movesDao;
});

final combosDaoProvider = Provider<CombosDao>((ref) {
  return ref.watch(databaseProvider).combosDao;
});

final reviewsDaoProvider = Provider<ReviewsDao>((ref) {
  return ref.watch(databaseProvider).reviewsDao;
});

final syncDaoProvider = Provider<SyncDao>((ref) {
  return ref.watch(databaseProvider).syncDao;
});

final fsrsCardsDaoProvider = Provider<FsrsCardsDao>((ref) {
  return ref.watch(databaseProvider).fsrsCardsDao;
});

final fsrsServiceProvider = Provider<FsrsService>((ref) {
  return FsrsService(ref.watch(fsrsCardsDaoProvider));
});

final decksDaoProvider = Provider<DecksDao>((ref) {
  return ref.watch(databaseProvider).decksDao;
});

final syncProvidersDaoProvider = Provider<SyncProvidersDao>((ref) {
  return ref.watch(databaseProvider).syncProvidersDao;
});

final deckServiceProvider = Provider<DeckService>((ref) {
  return DeckService(
    ref.watch(decksDaoProvider),
    ref.watch(movesDaoProvider),
    ref.watch(fsrsCardsDaoProvider),
  );
});

// Auth
final authServiceProvider = Provider<AuthService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthService(prefs);
});

final isLoggedInProvider = Provider<bool>((ref) {
  try {
    return ref.watch(authServiceProvider).isLoggedIn;
  } catch (_) {
    return false;
  }
});

// Repository providers (public API — use these in screens)
// When logged in, repos are wrapped with sync-aware decorators that log changes.
final moveRepositoryProvider = Provider<MoveRepository>((ref) {
  final inner = DriftMoveRepository(ref.watch(movesDaoProvider));
  if (!ref.watch(isLoggedInProvider)) return inner;
  return SyncAwareMoveRepository(inner, ref.watch(syncDaoProvider));
});

final comboRepositoryProvider = Provider<ComboRepository>((ref) {
  final inner = DriftComboRepository(ref.watch(combosDaoProvider));
  if (!ref.watch(isLoggedInProvider)) return inner;
  return SyncAwareComboRepository(inner, ref.watch(syncDaoProvider));
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final inner = DriftReviewRepository(ref.watch(reviewsDaoProvider));
  if (!ref.watch(isLoggedInProvider)) return inner;
  return SyncAwareReviewRepository(inner, ref.watch(syncDaoProvider));
});

final videoServiceProvider = Provider<VideoService>((ref) {
  return VideoService();
});

final reviewableNamingServiceProvider = Provider<ReviewableNamingService>((ref) {
  return ReviewableNamingService(
    movesDao: ref.watch(movesDaoProvider),
    combosDao: ref.watch(combosDaoProvider),
  );
});

// Sync
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    authService: ref.watch(authServiceProvider),
    syncDao: ref.watch(syncDaoProvider),
    db: ref.watch(databaseProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

final syncProgressProvider = StreamProvider<SyncProgress>((ref) {
  return ref.watch(syncServiceProvider).progressStream;
});

final pendingChangesCountProvider = StreamProvider<int>((ref) {
  return ref.watch(syncDaoProvider).watchPendingCount();
});

// Connectivity + auto-sync
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

final connectivityProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onlineStream;
});

final autoSyncEnabledProvider =
    NotifierProvider<AutoSyncNotifier, bool>(AutoSyncNotifier.new);

class AutoSyncNotifier extends Notifier<bool> {
  static const _key = 'auto_sync_enabled';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final newValue = !state;
    await prefs.setBool(_key, newValue);
    state = newValue;
  }
}

// Font family — persisted in SharedPreferences
final fontFamilyProvider =
    NotifierProvider<FontFamilyNotifier, AppFontFamily>(FontFamilyNotifier.new);

class FontFamilyNotifier extends Notifier<AppFontFamily> {
  static const _key = 'font_family';

  @override
  AppFontFamily build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppFontFamily.fromKey(prefs.getString(_key));
  }

  Future<void> set(AppFontFamily family) async {
    state = family;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, family.key);
  }
}

// Auto-sync trigger — watches connectivity + setting + pending count.
// Wrapped in try/catch so sync failures never crash the UI.
final syncTriggerProvider = Provider<void>((ref) {
  final isOnline = ref.watch(connectivityProvider).valueOrNull ?? false;
  final autoSync = ref.watch(autoSyncEnabledProvider);
  final isLoggedIn = ref.watch(isLoggedInProvider);
  final pendingCount = ref.watch(pendingChangesCountProvider).valueOrNull ?? 0;

  if (isOnline && autoSync && isLoggedIn && pendingCount > 0) {
    try {
      ref.read(syncServiceProvider).sync();
    } catch (_) {
      // Sync failure is non-fatal — will retry on next connectivity change
    }
  }
});

// ---------------------------------------------------------------------------
// Accent color — user-configurable global accent (defaults to AppColors.accent)
// ---------------------------------------------------------------------------

final accentColorProvider =
    NotifierProvider<AccentColorNotifier, Color>(AccentColorNotifier.new);

/// Persists custom accent color in SharedPreferences as an ARGB int.
/// The theme watches this provider so changing it updates the entire UI.
class AccentColorNotifier extends Notifier<Color> {
  static const _key = 'accent_color';

  @override
  Color build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final v = prefs.getInt(_key);
    return v != null ? Color(v) : AppColors.accent;
  }

  Future<void> set(Color color) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_key, color.toARGB32());
    state = color;
  }

  Future<void> reset() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_key);
    state = AppColors.accent;
  }
}

// ---------------------------------------------------------------------------
// Rating colors — configurable per-rating button colors
// ---------------------------------------------------------------------------

/// Immutable snapshot of the four rating colors.
class RatingColors {
  final Color again;
  final Color hard;
  final Color good;
  final Color easy;

  const RatingColors({
    required this.again,
    required this.hard,
    required this.good,
    required this.easy,
  });

  static const defaults = RatingColors(
    again: AppColors.actionAgain,
    hard: AppColors.actionHard,
    good: AppColors.actionGood,
    easy: AppColors.actionEasy,
  );

  /// Look up the color for a given rating name (AGAIN, HARD, GOOD, EASY).
  Color forName(String name) => switch (name) {
        'AGAIN' => again,
        'HARD' => hard,
        'GOOD' => good,
        'EASY' => easy,
        _ => again,
      };
}

final ratingColorsProvider =
    NotifierProvider<RatingColorsNotifier, RatingColors>(
  RatingColorsNotifier.new,
);

/// Persists custom rating colors in SharedPreferences as ARGB hex ints.
class RatingColorsNotifier extends Notifier<RatingColors> {
  static const _prefix = 'rating_color_';

  @override
  RatingColors build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return RatingColors(
      again: _read(prefs, 'again', AppColors.actionAgain),
      hard: _read(prefs, 'hard', AppColors.actionHard),
      good: _read(prefs, 'good', AppColors.actionGood),
      easy: _read(prefs, 'easy', AppColors.actionEasy),
    );
  }

  Color _read(SharedPreferences prefs, String key, Color fallback) {
    final v = prefs.getInt('$_prefix$key');
    return v != null ? Color(v) : fallback;
  }

  Future<void> setColor(String key, Color color) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt('$_prefix$key', color.toARGB32());
    state = RatingColors(
      again: key == 'again' ? color : state.again,
      hard: key == 'hard' ? color : state.hard,
      good: key == 'good' ? color : state.good,
      easy: key == 'easy' ? color : state.easy,
    );
  }

  Future<void> resetAll() async {
    final prefs = ref.read(sharedPreferencesProvider);
    for (final key in ['again', 'hard', 'good', 'easy']) {
      await prefs.remove('$_prefix$key');
    }
    state = RatingColors.defaults;
  }
}

// ---------------------------------------------------------------------------
// FSRS cards reactive stream — invalidates downstream providers on DB changes
// ---------------------------------------------------------------------------

/// Reactive stream watching all FSRS cards. Providers that depend on card data
/// should watch this to auto-refresh when reviews are processed.
final fsrsCardsRefreshProvider = StreamProvider<List<FsrsCard>>((ref) {
  return ref.watch(fsrsCardsDaoProvider).watchAll();
});

// ---------------------------------------------------------------------------
// Review mode — persisted toggle between Review and Deck views
// ---------------------------------------------------------------------------

final reviewModeProvider =
    NotifierProvider<ReviewModeNotifier, ReviewMode>(ReviewModeNotifier.new);

class ReviewModeNotifier extends Notifier<ReviewMode> {
  static const _key = 'review_mode';

  @override
  ReviewMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return ReviewMode.fromString(prefs.getString(_key));
  }

  Future<void> set(ReviewMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, mode.name);
  }
}

/// Static FSRS config provider for the SRS parameters card.
final fsrsConfigProvider = Provider<FsrsConfig>((_) => FsrsService.config);

// ---------------------------------------------------------------------------
// Native ML + 3D capabilities
// ---------------------------------------------------------------------------

/// On-device ML inference: pose detection + person segmentation.
/// Uses Apple Vision (built-in) and CoreML (DeepLabV3).
final visionMLProvider = Provider<VisionML>((_) => VisionML());

/// Metal-backed SceneKit 3D rendering for skeleton visualization.
final scene3DProvider = Provider<Scene3D>((_) => Scene3D());

// ---------------------------------------------------------------------------
// Asset Sync Engine — content-addressable video backup & sync
// ---------------------------------------------------------------------------

/// DAO for the content-addressable asset manifest.
final assetManifestDaoProvider = Provider<AssetManifestDao>((ref) {
  return ref.watch(databaseProvider).assetManifestDao;
});

/// DAO for tracking asset copies across storage providers.
final assetCopiesDaoProvider = Provider<AssetCopiesDao>((ref) {
  return ref.watch(databaseProvider).assetCopiesDao;
});

/// DAO for the sync operation queue.
final syncOperationsDaoProvider = Provider<SyncOperationsDao>((ref) {
  return ref.watch(databaseProvider).syncOperationsDao;
});

/// SHA-256 hashing service (runs in background isolates).
final assetHashServiceProvider = Provider<AssetHashService>((ref) {
  return AssetHashService();
});

/// Network policy for sync transfer decisions.
final networkPolicyProvider = Provider<NetworkPolicy>((ref) {
  return NetworkPolicy(ref.watch(sharedPreferencesProvider));
});

/// Two-copy enforcement guard.
final safetyGuardProvider = Provider<SafetyGuard>((ref) {
  return SafetyGuard(
    ref.watch(assetManifestDaoProvider),
    ref.watch(assetCopiesDaoProvider),
  );
});

/// Configured cloud providers — watches sync_providers table and instantiates
/// the corresponding [CloudProvider] subclass for each enabled row.
final cloudProvidersProvider = StreamProvider<List<CloudProvider>>((ref) {
  return ref.watch(syncProvidersDaoProvider).watchAll().map((rows) {
    final providers = <CloudProvider>[];
    for (final row in rows) {
      if (!row.enabled) continue;
      switch (row.providerType) {
        case 'icloud':
          providers.add(ICloudProvider());
        case 'gdrive':
          final gdriveProvider = GDriveProvider();
          // Restore cached folder ID from config to skip lookup
          if (row.configJson != null) {
            try {
              final config =
                  (jsonDecode(row.configJson!) as Map<String, dynamic>);
              gdriveProvider.configFolderId = config['folderId'] as String?;
            } catch (_) {}
          }
          providers.add(gdriveProvider);
        default:
          break;
      }
    }
    return providers;
  });
});

/// Main asset sync engine orchestrator.
final assetSyncEngineProvider = Provider<asset_sync.AssetSyncEngine>((ref) {
  final engine = asset_sync.AssetSyncEngine(
    manifestDao: ref.watch(assetManifestDaoProvider),
    copiesDao: ref.watch(assetCopiesDaoProvider),
    opsDao: ref.watch(syncOperationsDaoProvider),
    hashService: ref.watch(assetHashServiceProvider),
    networkPolicy: ref.watch(networkPolicyProvider),
    safetyGuard: ref.watch(safetyGuardProvider),
    providers: ref.watch(cloudProvidersProvider).valueOrNull ?? [],
  );
  ref.onDispose(() => engine.dispose());
  return engine;
});

/// Reactive stream of sync progress for UI display.
final assetSyncProgressProvider =
    StreamProvider<asset_sync.SyncProgress>((ref) {
  return ref.watch(assetSyncEngineProvider).progressStream;
});

/// Integrity verifier for periodic file re-hashing.
final integrityVerifierProvider = Provider<IntegrityVerifier>((ref) {
  return IntegrityVerifier(
    ref.watch(assetManifestDaoProvider),
    ref.watch(assetCopiesDaoProvider),
    ref.watch(assetHashServiceProvider),
  );
});

/// Legacy asset migration (v9 → v10 schema).
final legacyAssetMigrationProvider = Provider<LegacyAssetMigration>((ref) {
  return LegacyAssetMigration(
    movesDao: ref.watch(movesDaoProvider),
    manifestDao: ref.watch(assetManifestDaoProvider),
    copiesDao: ref.watch(assetCopiesDaoProvider),
    hashService: ref.watch(assetHashServiceProvider),
    db: ref.watch(databaseProvider),
  );
});

/// Tombstone cleaner for 30-day grace period cleanup.
final tombstoneCleanerProvider = Provider<TombstoneCleaner>((ref) {
  return TombstoneCleaner(
    manifestDao: ref.watch(assetManifestDaoProvider),
    copiesDao: ref.watch(assetCopiesDaoProvider),
    opsDao: ref.watch(syncOperationsDaoProvider),
    providers: ref.watch(cloudProvidersProvider).valueOrNull ?? [],
  );
});

/// Background sync manager.
final backgroundSyncManagerProvider = Provider<BackgroundSyncManager>((ref) {
  return BackgroundSyncManager();
});

/// Post-import hook: hash → manifest → copy → queue upload → sync cycle.
final videoImportSyncHookProvider = Provider<VideoImportSyncHook>((ref) {
  return VideoImportSyncHook(
    hashService: ref.watch(assetHashServiceProvider),
    manifestDao: ref.watch(assetManifestDaoProvider),
    copiesDao: ref.watch(assetCopiesDaoProvider),
    movesDao: ref.watch(movesDaoProvider),
    syncEngine: ref.watch(assetSyncEngineProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
  );
});

// ---------------------------------------------------------------------------
// Manifest sync — debounced upload of manifest.json to cloud storage
// ---------------------------------------------------------------------------

/// Serializes the full library into a compact manifest.json for web viewer.
final manifestSerializerProvider = Provider<ManifestSerializer>((ref) {
  return ManifestSerializer(
    movesDao: ref.watch(movesDaoProvider),
    combosDao: ref.watch(combosDaoProvider),
    fsrsCardsDao: ref.watch(fsrsCardsDaoProvider),
    reviewsDao: ref.watch(reviewsDaoProvider),
    decksDao: ref.watch(decksDaoProvider),
    db: ref.watch(databaseProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

/// Debounced manifest uploader — triggers 5s after last metadata change.
final manifestSyncServiceProvider = Provider<ManifestSyncService>((ref) {
  final service = ManifestSyncService(
    serializer: ref.watch(manifestSerializerProvider),
    getProviders: () => ref.read(cloudProvidersProvider).valueOrNull ?? [],
  );
  ref.onDispose(() => service.dispose());
  return service;
});

/// Reactive trigger: watches all metadata streams and notifies manifest sync.
/// This provider exists solely for its side effect — reading it activates
/// the watch subscriptions that drive manifest uploads.
///
/// Must be read once at app startup (e.g., in BreakdexApp.build) to activate.
final manifestSyncTriggerProvider = Provider<void>((ref) {
  final syncService = ref.watch(manifestSyncServiceProvider);

  void onChange() => syncService.onMetadataChanged();

  // Subscribe to all reactive DAO streams that affect manifest content
  final moveSub = ref.watch(movesDaoProvider).watchAll().listen((_) => onChange());
  final comboSub = ref.watch(combosDaoProvider).watchAll().listen((_) => onChange());
  final fsrsSub = ref.watch(fsrsCardsDaoProvider).watchAll().listen((_) => onChange());
  final reviewSub = ref.watch(reviewsDaoProvider).watchAll().listen((_) => onChange());

  ref.onDispose(() {
    moveSub.cancel();
    comboSub.cancel();
    fsrsSub.cancel();
    reviewSub.cancel();
  });
});

// ---------------------------------------------------------------------------
// iCloud availability + onboarding
// ---------------------------------------------------------------------------

/// Auto-detect iCloud on device (no DB write, just checks entitlement).
final iCloudAvailableProvider = FutureProvider<bool>((ref) async {
  if (!Platform.isIOS) return false;
  return ICloudProvider().authenticate();
});

/// Whether the sync onboarding card has been shown/dismissed.
final syncOnboardingShownProvider = StateProvider<bool>((ref) {
  return ref.watch(sharedPreferencesProvider).getBool('sync_onboarding_shown') ?? false;
});

/// One-tap iCloud setup orchestrator.
final iCloudSetupProvider = Provider<ICloudSetupService>((ref) {
  return ICloudSetupService(
    syncProvidersDao: ref.watch(syncProvidersDaoProvider),
  );
});

/// Google Drive OAuth setup orchestrator.
final gDriveSetupProvider = Provider<GDriveSetupService>((ref) {
  return GDriveSetupService(
    syncProvidersDao: ref.watch(syncProvidersDaoProvider),
  );
});

// ---------------------------------------------------------------------------
// Free Up Space — local storage management
// ---------------------------------------------------------------------------

/// Space manager for analyzing and freeing local video copies.
final spaceManagerProvider = Provider<SpaceManager>((ref) {
  return SpaceManager(
    manifestDao: ref.watch(assetManifestDaoProvider),
    copiesDao: ref.watch(assetCopiesDaoProvider),
    safetyGuard: ref.watch(safetyGuardProvider),
  );
});

/// Triggers an asset sync cycle when connectivity changes from offline → online.
/// Must be watched in BreakdexApp.build to activate.
final syncConnectivityTriggerProvider = Provider<void>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  ConnectionType? previousType;

  final sub = connectivityService.connectionTypeStream.listen((type) {
    final wasOffline = previousType == ConnectionType.none || previousType == null;
    final nowOnline = type != ConnectionType.none;
    previousType = type;

    if (wasOffline && nowOnline) {
      debugPrint('[SyncConnectivity] Back online ($type) — triggering sync');
      try {
        ref.read(assetSyncEngineProvider).runSyncCycle(type);
      } catch (e) {
        debugPrint('[SyncConnectivity] Sync trigger failed: $e');
      }
    }
  });

  ref.onDispose(() => sub.cancel());
});

// ---------------------------------------------------------------------------
// Sync Health — at-a-glance sync status for settings UI
// ---------------------------------------------------------------------------

/// Overall sync health for the settings badge.
enum SyncHealth {
  /// All assets backed up to cloud.
  allSynced,

  /// Sync engine is actively transferring.
  syncing,

  /// There are queued uploads waiting.
  pendingUpload,

  /// One or more operations have failed.
  error,

  /// No cloud providers configured.
  noProviders,
}

/// Computed provider combining engine state + provider config → single health enum.
final syncHealthProvider = Provider<SyncHealth>((ref) {
  final providers = ref.watch(cloudProvidersProvider).valueOrNull ?? [];
  if (providers.isEmpty) return SyncHealth.noProviders;

  final progress = ref.watch(assetSyncProgressProvider).valueOrNull;
  if (progress == null) return SyncHealth.allSynced;

  return switch (progress.state) {
    asset_sync.SyncEngineState.error => SyncHealth.error,
    asset_sync.SyncEngineState.uploading ||
    asset_sync.SyncEngineState.downloading ||
    asset_sync.SyncEngineState.hashing ||
    asset_sync.SyncEngineState.verifying =>
      SyncHealth.syncing,
    _ when progress.pendingUploads > 0 => SyncHealth.pendingUpload,
    _ => SyncHealth.allSynced,
  };
});

/// On-demand downloader for re-downloading freed videos from cloud.
final onDemandDownloaderProvider = Provider<OnDemandDownloader>((ref) {
  return OnDemandDownloader(
    manifestDao: ref.watch(assetManifestDaoProvider),
    copiesDao: ref.watch(assetCopiesDaoProvider),
    hashService: ref.watch(assetHashServiceProvider),
    getProviders: () => ref.read(cloudProvidersProvider).valueOrNull ?? [],
  );
});
