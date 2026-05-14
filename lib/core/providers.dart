import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/database.dart';
import 'database/daos/moves_dao.dart';
import 'database/daos/combos_dao.dart';
import 'database/daos/reviews_dao.dart';
import 'database/daos/sync_dao.dart';
import 'database/daos/fsrs_cards_dao.dart';
import 'database/daos/decks_dao.dart';
import 'database/daos/sync_providers_dao.dart';
import 'database/daos/sets_dao.dart';
import 'database/daos/provenance_events_dao.dart';
import 'data/repositories.dart';
import 'data/drift_repositories.dart';
import 'data/sync_aware_repositories.dart';
import 'design/colors.dart';
import 'design/typography.dart';
import 'models/learning_state.dart';
import 'models/learning_state_colors.dart';
import 'models/provenance_report.dart';
import 'models/review_card_display_settings.dart';
import 'models/reviewable_item.dart';
import 'services/auth_service.dart';
import 'services/settings_service.dart';
import 'services/video_service.dart';
import 'services/media_cleanup_service.dart';
import 'services/canonical_folder_service.dart';
import 'services/canonical_import_gate.dart';
import 'services/canonical_reconcile_service.dart';
import 'services/database_recovery_service.dart';
import 'services/managed_album_reconciliation_service.dart';
import 'services/media_playback_coordinator.dart';
import 'services/move_creation_service.dart';
import 'services/sync_service.dart';
import 'services/connectivity_service.dart';
import 'services/fsrs_service.dart';
import 'services/manual_review_state_service.dart';
import 'services/deck_service.dart';
import 'services/reviewable_naming_service.dart';
import 'services/native_video_album.dart';
import 'services/provenance_journal_service.dart';
import 'services/provenance_report_service.dart';
import 'services/provenance_service.dart';
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
import 'sync/video_reliability_runtime.dart';
import 'sync/video_retrieval_controller.dart';
import 'sync/video_import_sync_hook.dart';

part 'providers/sync_providers.dart';
part 'providers/theme_providers.dart';
part 'providers/review_card_display_providers.dart';
part 'providers/learning_state_label_providers.dart';
part 'providers/video_playback_preferences_providers.dart';
part 'providers/canonical_storage_providers.dart';

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

final manualReviewStateServiceProvider = Provider<ManualReviewStateService>((
  ref,
) {
  return ManualReviewStateService(
    moveRepository: ref.watch(moveRepositoryProvider),
    fsrsCardsDao: ref.watch(fsrsCardsDaoProvider),
    fsrsService: ref.watch(fsrsServiceProvider),
    syncDao: ref.watch(syncDaoProvider),
  );
});

final decksDaoProvider = Provider<DecksDao>((ref) {
  return ref.watch(databaseProvider).decksDao;
});

final setsDaoProvider = Provider<SetsDao>((ref) {
  return SetsDao(ref.watch(databaseProvider));
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
  return SyncAwareMoveRepository(inner, ref.watch(syncDaoProvider),
      provenance: ref.watch(provenanceServiceProvider));
});

final comboRepositoryProvider = Provider<ComboRepository>((ref) {
  final inner = DriftComboRepository(ref.watch(combosDaoProvider));
  if (!ref.watch(isLoggedInProvider)) return inner;
  return SyncAwareComboRepository(inner, ref.watch(syncDaoProvider),
      provenance: ref.watch(provenanceServiceProvider));
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final inner = DriftReviewRepository(ref.watch(reviewsDaoProvider));
  if (!ref.watch(isLoggedInProvider)) return inner;
  return SyncAwareReviewRepository(inner, ref.watch(syncDaoProvider),
      provenance: ref.watch(provenanceServiceProvider));
});

final setRepositoryProvider = Provider<SetRepository>((ref) {
  final inner = DriftSetRepository(ref.watch(setsDaoProvider));
  if (!ref.watch(isLoggedInProvider)) return inner;
  return SyncAwareSetRepository(inner, ref.watch(syncDaoProvider),
      provenance: ref.watch(provenanceServiceProvider));
});

final videoServiceProvider = Provider<VideoService>((ref) {
  return VideoService();
});

final mediaPlaybackCoordinatorProvider = Provider<MediaPlaybackCoordinator>((
  ref,
) {
  return mediaPlaybackCoordinator;
});

final mediaCleanupServiceProvider = Provider<MediaCleanupService>((ref) {
  return MediaCleanupService(
    db: ref.watch(databaseProvider),
    videoService: ref.watch(videoServiceProvider),
  );
});

final nativeVideoAlbumProvider = Provider<NativeVideoAlbum>((ref) {
  return NativeVideoAlbum();
});

final managedAlbumReconciliationServiceProvider =
    Provider<ManagedAlbumReconciliationService>((ref) {
      return ManagedAlbumReconciliationService(
        movesDao: ref.watch(movesDaoProvider),
        moveRepository: ref.watch(moveRepositoryProvider),
        moveCreationService: ref.watch(moveCreationServiceProvider),
        mediaCleanupService: ref.watch(mediaCleanupServiceProvider),
        videoAlbum: ref.watch(nativeVideoAlbumProvider),
        videoService: ref.watch(videoServiceProvider),
        provenanceJournal: ref.watch(provenanceJournalServiceProvider),
      );
    });

final managedAlbumLifecycleProvider = Provider<ManagedAlbumLifecycleController>(
  (ref) {
    final controller = ManagedAlbumLifecycleController(
      service: ref.watch(managedAlbumReconciliationServiceProvider),
      videoAlbum: ref.watch(nativeVideoAlbumProvider),
    );
    controller.start();
    ref.onDispose(() {
      unawaited(controller.dispose());
    });
    return controller;
  },
);

final managedAlbumLifecycleReportProvider =
    StreamProvider<ManagedAlbumReconcileReport>((ref) {
      final controller = ref.watch(managedAlbumLifecycleProvider);
      final latest = controller.latestReport;
      if (latest == null) {
        return controller.reports;
      }
      return Stream<ManagedAlbumReconcileReport>.multi((stream) {
        stream.add(latest);
        final sub = controller.reports.listen(
          stream.add,
          onError: stream.addError,
        );
        stream.onCancel = sub.cancel;
      });
    });

final databaseRecoveryServiceProvider = Provider<DatabaseRecoveryService>((
  ref,
) {
  return DatabaseRecoveryService();
});

final automaticDatabaseBackupLifecycleProvider = Provider<void>((ref) {
  final controller = AutomaticDatabaseBackupController(
    service: ref.watch(databaseRecoveryServiceProvider),
  );
  controller.start();
  ref.onDispose(() {
    unawaited(controller.dispose());
  });
});

final provenanceJournalServiceProvider = Provider<ProvenanceJournalService>((
  ref,
) {
  return ProvenanceJournalService();
});

final provenanceDaoProvider = Provider<ProvenanceEventsDao>((ref) {
  return ProvenanceEventsDao(ref.watch(databaseProvider));
});

final provenanceServiceProvider = Provider<ProvenanceService>((ref) {
  return ProvenanceService(ref.watch(provenanceDaoProvider));
});

final provenanceReportServiceProvider = Provider<ProvenanceReportService>((
  ref,
) {
  return ProvenanceReportService(ref.watch(provenanceJournalServiceProvider));
});

final provenanceReportProvider = FutureProvider<ProvenanceReport>((ref) {
  return ref.watch(provenanceReportServiceProvider).loadReport();
});

final reviewableNamingServiceProvider = Provider<ReviewableNamingService>((
  ref,
) {
  return ReviewableNamingService(
    movesDao: ref.watch(movesDaoProvider),
    combosDao: ref.watch(combosDaoProvider),
  );
});

final moveCreationServiceProvider = Provider<MoveCreationService>((ref) {
  return MoveCreationService(
    moveRepository: ref.watch(moveRepositoryProvider),
    namingService: ref.watch(reviewableNamingServiceProvider),
    videoAlbum: ref.watch(nativeVideoAlbumProvider),
    onVideoImported: ({required localPath, required moveId}) {
      return ref
          .read(videoImportSyncHookProvider)
          .onVideoImported(localPath: localPath, moveId: moveId);
    },
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

final autoSyncEnabledProvider = NotifierProvider<AutoSyncNotifier, bool>(
  AutoSyncNotifier.new,
);

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

final reviewModeProvider = NotifierProvider<ReviewModeNotifier, ReviewMode>(
  ReviewModeNotifier.new,
);

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
// Tab visibility — tracks which bottom-nav tab is active
// ---------------------------------------------------------------------------
final currentTabIndexProvider = StateProvider<int>((_) => 0);
