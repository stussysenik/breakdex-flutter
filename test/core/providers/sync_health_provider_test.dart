import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/sync/asset_sync_engine.dart';
import 'package:breakdex/core/sync/cloud_provider.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

/// Minimal provider stand-in — health only cares that one is configured.
class _StubProvider implements CloudProvider {
  @override
  String get providerType => 'gdrive';

  @override
  String get displayName => 'Stub Drive';

  @override
  Set<CloudProviderCapability> get capabilities => const {};

  @override
  Future<bool> authenticate() async => true;

  @override
  Future<void> deauthenticate() async {}

  @override
  Future<bool> get isAuthenticated async => true;

  @override
  Future<RemoteAsset> upload({
    required final String localPath,
    required final String remotePath,
    final TransferProgress? onProgress,
    final CancellationToken? cancel,
  }) async =>
      RemoteAsset(remotePath: remotePath, sizeBytes: 0);

  @override
  Future<void> download({
    required final String remotePath,
    required final String localPath,
    final TransferProgress? onProgress,
    final CancellationToken? cancel,
  }) async {}

  @override
  Future<bool> verify({
    required final String remotePath,
    final String? expectedHash,
    final int? expectedSize,
  }) async =>
      true;

  @override
  Future<List<RemoteAsset>> list({required final String directory}) async => [];

  @override
  Future<void> delete({required final String remotePath}) async {}

  @override
  Future<({int totalBytes, int usedBytes})?> quota() async => null;
}

Future<void> _seedAsset(
  final AppDatabase db, {
  required final String hash,
  final int copyCount = 0,
}) async {
  await db.assetManifestDao.upsert(AssetManifestCompanion(
    contentHash: Value(hash),
    fileSizeBytes: const Value(1024),
    sourceType: const Value('camera'),
    importedAt: Value(DateTime.now()),
    copyCount: Value(copyCount),
  ));
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = createTestDatabase();
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      cloudProvidersProvider.overrideWith(
        (final ref) => Stream.value(<CloudProvider>[_StubProvider()]),
      ),
      // The engine only emits on state transitions — a fresh app launch has a
      // silent progress stream. Health must not read that as "all synced".
      assetSyncProgressProvider.overrideWith(
        (final ref) => const Stream<SyncProgress>.empty(),
      ),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('syncHealthProvider (D1 — derive from the store, not the stream)', () {
    test(
        'silent progress stream + 1 underprotected row reports pendingUpload, '
        'never a defaulted allSynced', () async {
      await _seedAsset(db, hash: 'unprotected1');

      final states = <SyncHealth>[];
      container.listen(syncHealthProvider, (final _, final next) {
        states.add(next);
      }, fireImmediately: true);
      await pumpEventQueue();

      expect(container.read(syncHealthProvider), SyncHealth.pendingUpload);
      expect(states, isNot(contains(SyncHealth.allSynced)),
          reason: 'allSynced must never appear while an asset lacks copies');
    });

    test('allSynced only once the store proves zero underprotected assets',
        () async {
      await _seedAsset(db, hash: 'protected1', copyCount: 2);

      container.listen(syncHealthProvider, (final _, final _) {});
      await pumpEventQueue();

      expect(container.read(syncHealthProvider), SyncHealth.allSynced);
    });

    test('no configured providers wins regardless of counts', () async {
      await _seedAsset(db, hash: 'unprotected2');
      final bare = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        cloudProvidersProvider.overrideWith(
          (final ref) => Stream.value(const <CloudProvider>[]),
        ),
        assetSyncProgressProvider.overrideWith(
          (final ref) => const Stream<SyncProgress>.empty(),
        ),
      ]);
      addTearDown(bare.dispose);

      bare.listen(syncHealthProvider, (final _, final _) {});
      await pumpEventQueue();

      expect(bare.read(syncHealthProvider), SyncHealth.noProviders);
    });
  });
}
