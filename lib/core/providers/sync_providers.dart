part of '../providers.dart';

// ---------------------------------------------------------------------------
// Asset Sync Engine — content-addressable video backup & sync
// ---------------------------------------------------------------------------

/// DAO for the content-addressable asset manifest.
final assetManifestDaoProvider = Provider<AssetManifestDao>((final ref) {
  return ref.watch(databaseProvider).assetManifestDao;
});

/// DAO for tracking asset copies across storage providers.
final assetCopiesDaoProvider = Provider<AssetCopiesDao>((final ref) {
  return ref.watch(databaseProvider).assetCopiesDao;
});

/// DAO for the sync operation queue.
final syncOperationsDaoProvider = Provider<SyncOperationsDao>((final ref) {
  return ref.watch(databaseProvider).syncOperationsDao;
});

/// SHA-256 hashing service (runs in background isolates).
final assetHashServiceProvider = Provider<AssetHashService>((final ref) {
  return AssetHashService();
});

/// Network policy for sync transfer decisions.
final networkPolicyProvider = Provider<NetworkPolicy>((final ref) {
  return NetworkPolicy(ref.watch(sharedPreferencesProvider));
});

/// Two-copy enforcement guard.
final safetyGuardProvider = Provider<SafetyGuard>((final ref) {
  return SafetyGuard(
    ref.watch(assetManifestDaoProvider),
    ref.watch(assetCopiesDaoProvider),
  );
});

/// Configured cloud providers — watches sync_providers table and instantiates
/// the corresponding [CloudProvider] subclass for each enabled row.
final cloudProvidersProvider = StreamProvider<List<CloudProvider>>((final ref) {
  return ref.watch(syncProvidersDaoProvider).watchAll().map((final rows) {
    final providers = <CloudProvider>[];
    for (final row in rows) {
      if (!row.enabled) continue;
      switch (row.providerType) {
        case 'firebase':
          providers.add(FirebaseStorageProvider());
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
final assetSyncEngineProvider = Provider<asset_sync.AssetSyncEngine>((final ref) {
  final engine = asset_sync.AssetSyncEngine(
    manifestDao: ref.watch(assetManifestDaoProvider),
    copiesDao: ref.watch(assetCopiesDaoProvider),
    opsDao: ref.watch(syncOperationsDaoProvider),
    hashService: ref.watch(assetHashServiceProvider),
    networkPolicy: ref.watch(networkPolicyProvider),
    safetyGuard: ref.watch(safetyGuardProvider),
    providers: ref.watch(cloudProvidersProvider).valueOrNull ?? [],
    syncDao: ref.watch(syncDaoProvider),
  );
  ref.onDispose(() => engine.dispose());
  return engine;
});

/// Reactive stream of sync progress for UI display.
final assetSyncProgressProvider = StreamProvider<asset_sync.SyncProgress>((
  final ref,
) {
  return ref.watch(assetSyncEngineProvider).progressStream;
});

/// Integrity verifier for periodic file re-hashing.
final integrityVerifierProvider = Provider<IntegrityVerifier>((final ref) {
  return IntegrityVerifier(
    ref.watch(assetManifestDaoProvider),
    ref.watch(assetCopiesDaoProvider),
    ref.watch(assetHashServiceProvider),
  );
});

/// Legacy asset migration (v9 → v10 schema).
final legacyAssetMigrationProvider = Provider<LegacyAssetMigration>((final ref) {
  return LegacyAssetMigration(
    movesDao: ref.watch(movesDaoProvider),
    manifestDao: ref.watch(assetManifestDaoProvider),
    copiesDao: ref.watch(assetCopiesDaoProvider),
    hashService: ref.watch(assetHashServiceProvider),
    db: ref.watch(databaseProvider),
  );
});

/// Tombstone cleaner for 30-day grace period cleanup.
final tombstoneCleanerProvider = Provider<TombstoneCleaner>((final ref) {
  return TombstoneCleaner(
    manifestDao: ref.watch(assetManifestDaoProvider),
    copiesDao: ref.watch(assetCopiesDaoProvider),
    opsDao: ref.watch(syncOperationsDaoProvider),
    providers: ref.watch(cloudProvidersProvider).valueOrNull ?? [],
  );
});

/// Background sync manager.
final backgroundSyncManagerProvider = Provider<BackgroundSyncManager>((final ref) {
  return BackgroundSyncManager();
});

/// Post-import hook: hash → manifest → copy → queue upload → sync cycle.
final videoImportSyncHookProvider = Provider<VideoImportSyncHook>((final ref) {
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
final manifestSerializerProvider = Provider<ManifestSerializer>((final ref) {
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
final manifestSyncServiceProvider = Provider<ManifestSyncService>((final ref) {
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
final manifestSyncTriggerProvider = Provider<void>((final ref) {
  final syncService = ref.watch(manifestSyncServiceProvider);

  void onChange() => syncService.onMetadataChanged();

  // Subscribe to all reactive DAO streams that affect manifest content
  final moveSub = ref
      .watch(movesDaoProvider)
      .watchAll()
      .listen((_) => onChange());
  final comboSub = ref
      .watch(combosDaoProvider)
      .watchAll()
      .listen((_) => onChange());
  final fsrsSub = ref
      .watch(fsrsCardsDaoProvider)
      .watchAll()
      .listen((_) => onChange());
  final reviewSub = ref
      .watch(reviewsDaoProvider)
      .watchAll()
      .listen((_) => onChange());

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
final iCloudAvailableProvider = FutureProvider<bool>((final ref) async {
  if (!Platform.isIOS) return false;
  return ICloudProvider().authenticate();
});

/// Whether the sync onboarding card has been shown/dismissed.
final syncOnboardingShownProvider = StateProvider<bool>((final ref) {
  return ref
          .watch(sharedPreferencesProvider)
          .getBool('sync_onboarding_shown') ??
      false;
});

/// One-tap iCloud setup orchestrator.
final iCloudSetupProvider = Provider<ICloudSetupService>((final ref) {
  return ICloudSetupService(
    syncProvidersDao: ref.watch(syncProvidersDaoProvider),
  );
});

/// Google Drive OAuth setup orchestrator.
final gDriveSetupProvider = Provider<GDriveSetupService>((final ref) {
  return GDriveSetupService(
    syncProvidersDao: ref.watch(syncProvidersDaoProvider),
  );
});

// ---------------------------------------------------------------------------
// Free Up Space — local storage management
// ---------------------------------------------------------------------------

/// Space manager for analyzing and freeing local video copies.
final spaceManagerProvider = Provider<SpaceManager>((final ref) {
  return SpaceManager(
    manifestDao: ref.watch(assetManifestDaoProvider),
    copiesDao: ref.watch(assetCopiesDaoProvider),
    safetyGuard: ref.watch(safetyGuardProvider),
  );
});

/// Triggers an asset sync cycle when connectivity changes from offline → online.
/// Must be watched in BreakdexApp.build to activate.
final syncConnectivityTriggerProvider = Provider<void>((final ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  ConnectionType? previousType;
  var hasSeenInitialType = false;

  final sub = connectivityService.connectionTypeStream.listen((final type) {
    if (!hasSeenInitialType) {
      hasSeenInitialType = true;
      previousType = type;
      return;
    }

    final wasOffline = previousType == ConnectionType.none;
    final nowOnline = type != ConnectionType.none;
    final changed = previousType != type;
    previousType = type;

    if (changed && wasOffline && nowOnline) {
      debugPrint('[SyncConnectivity] Back online ($type) — triggering sync');
      try {
        ref.read(assetSyncEngineProvider).runSyncCycle(type);
      } catch (e) {
        debugPrint('[SyncConnectivity] Sync trigger failed: $e');
      }
    }
  });

  Future<void>.microtask(() async {
    if (hasSeenInitialType) return;
    previousType = await connectivityService.checkType();
    hasSeenInitialType = true;
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
final syncHealthProvider = Provider<SyncHealth>((final ref) {
  final providers = ref.watch(cloudProvidersProvider).valueOrNull ?? [];
  if (providers.isEmpty) return SyncHealth.noProviders;

  final progress = ref.watch(assetSyncProgressProvider).valueOrNull;
  if (progress == null) return SyncHealth.allSynced;

  return switch (progress.state) {
    asset_sync.SyncEngineState.error => SyncHealth.error,
    asset_sync.SyncEngineState.uploading ||
    asset_sync.SyncEngineState.downloading ||
    asset_sync.SyncEngineState.hashing ||
    asset_sync.SyncEngineState.verifying => SyncHealth.syncing,
    _ when progress.pendingUploads > 0 => SyncHealth.pendingUpload,
    _ => SyncHealth.allSynced,
  };
});

/// On-demand downloader for re-downloading freed videos from cloud.
final onDemandDownloaderProvider = Provider<OnDemandDownloader>((final ref) {
  return OnDemandDownloader(
    manifestDao: ref.watch(assetManifestDaoProvider),
    copiesDao: ref.watch(assetCopiesDaoProvider),
    hashService: ref.watch(assetHashServiceProvider),
    getProviders: () => ref.read(cloudProvidersProvider).valueOrNull ?? [],
    syncDao: ref.watch(syncDaoProvider),
  );
});

/// Controller for user-initiated cloud video retrieval.
final videoRetrievalControllerProvider = Provider<VideoRetrievalController>((
  final ref,
) {
  final controller = VideoRetrievalController(
    retriever: ref.watch(onDemandDownloaderProvider),
    manifestDao: ref.watch(assetManifestDaoProvider),
    networkPolicy: ref.watch(networkPolicyProvider),
    getConnectionType: () => ref.read(connectivityServiceProvider).checkType(),
    connectionTypeStream: ref
        .watch(connectivityServiceProvider)
        .connectionTypeStream,
    provenanceJournal: ref.watch(provenanceJournalServiceProvider),
    syncDao: ref.watch(syncDaoProvider),
    clock: ref.watch(appClockProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

final videoRetrievalStatusProvider =
    StreamProvider.family<VideoRetrievalSnapshot, String>((final ref, final contentHash) {
      return ref.watch(videoRetrievalControllerProvider).watch(contentHash);
    });

final videoReliabilityRuntimeProvider = Provider<VideoReliabilityRuntime>((
  final ref,
) {
  final runtime = VideoReliabilityRuntime(
    movesDao: ref.watch(movesDaoProvider),
    moveRepository: ref.watch(moveRepositoryProvider),
    videoService: ref.watch(videoServiceProvider),
    retrievalController: ref.watch(videoRetrievalControllerProvider),
    connectionTypeStream: ref
        .watch(connectivityServiceProvider)
        .connectionTypeStream,
  );
  ref.onDispose(() {
    unawaited(runtime.dispose());
  });
  return runtime;
});

final videoReliabilityLifecycleProvider = Provider<void>((final ref) {
  ref.watch(videoReliabilityRuntimeProvider).start();
});

final videoReliabilityReportProvider = StreamProvider<VideoReliabilityReport>((
  final ref,
) {
  final runtime = ref.watch(videoReliabilityRuntimeProvider);
  final latest = runtime.latestReport;
  if (latest == null) {
    return runtime.reports;
  }
  return Stream<VideoReliabilityReport>.multi((final controller) {
    controller.add(latest);
    final sub = runtime.reports.listen(
      controller.add,
      onError: controller.addError,
    );
    controller.onCancel = sub.cancel;
  });
});
