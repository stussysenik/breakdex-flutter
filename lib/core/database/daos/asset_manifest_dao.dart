import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/asset_manifest.dart';
import '../tables/asset_copies.dart';

part 'asset_manifest_dao.g.dart';

@DriftAccessor(tables: [AssetManifest, AssetCopies])
class AssetManifestDao extends DatabaseAccessor<AppDatabase>
    with _$AssetManifestDaoMixin {
  AssetManifestDao(super.db);

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  Stream<List<AssetManifestData>> watchAll() => (select(
    assetManifest,
  )..orderBy([(t) => OrderingTerm.desc(t.importedAt)])).watch();

  Future<List<AssetManifestData>> getAll() => (select(
    assetManifest,
  )..orderBy([(t) => OrderingTerm.desc(t.importedAt)])).get();

  Future<AssetManifestData?> getByHash(String contentHash) => (select(
    assetManifest,
  )..where((t) => t.contentHash.equals(contentHash))).getSingleOrNull();

  Stream<AssetManifestData?> watchByHash(String contentHash) => (select(
    assetManifest,
  )..where((t) => t.contentHash.equals(contentHash))).watchSingleOrNull();

  /// Assets that don't have enough cloud copies yet.
  Future<List<AssetManifestData>> getUnderprotected({int minCopies = 2}) =>
      (select(assetManifest)..where(
            (t) =>
                t.copyCount.isSmallerThanValue(minCopies) &
                t.deletedAt.isNull(),
          ))
          .get();

  /// Assets pending local verification (never verified, or stale).
  Future<List<AssetManifestData>> getStaleVerifications(Duration maxAge) async {
    final cutoff = DateTime.now().subtract(maxAge);
    return (select(assetManifest)..where(
          (t) =>
              t.deletedAt.isNull() &
              t.localPath.isNotNull() &
              (t.localVerifiedAt.isNull() |
                  t.localVerifiedAt.isSmallerThanValue(cutoff)),
        ))
        .get();
  }

  /// Soft-deleted assets past the grace period, ready for hard deletion.
  Future<List<AssetManifestData>> getTombstonedBefore(DateTime cutoff) =>
      (select(assetManifest)..where(
            (t) =>
                t.deletedAt.isNotNull() &
                t.deletedAt.isSmallerThanValue(cutoff),
          ))
          .get();

  /// Total count of live (non-deleted) assets.
  Future<int> countLive() async {
    final count = assetManifest.contentHash.count();
    final query = selectOnly(assetManifest)
      ..addColumns([count])
      ..where(assetManifest.deletedAt.isNull());
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  Future<void> upsert(AssetManifestCompanion entry) =>
      into(assetManifest).insertOnConflictUpdate(entry);

  Future<void> insertManifest(AssetManifestCompanion entry) =>
      into(assetManifest).insert(entry, mode: InsertMode.insertOrIgnore);

  /// Update only the local copy fields without re-validating required columns.
  Future<void> updateLocalState(
    String contentHash, {
    Value<String?> localPath = const Value.absent(),
    Value<DateTime?> localVerifiedAt = const Value.absent(),
  }) => (update(assetManifest)..where((t) => t.contentHash.equals(contentHash)))
      .write(
        AssetManifestCompanion(
          localPath: localPath,
          localVerifiedAt: localVerifiedAt,
        ),
      );

  /// Soft-delete an asset (sets deletedAt + tombstoneReason).
  Future<void> softDelete(String contentHash, String reason) =>
      (update(
        assetManifest,
      )..where((t) => t.contentHash.equals(contentHash))).write(
        AssetManifestCompanion(
          deletedAt: Value(DateTime.now()),
          tombstoneReason: Value(reason),
        ),
      );

  /// Update copy count after a copy is added or removed.
  Future<void> updateCopyCount(String contentHash) async {
    final copies =
        await (select(assetCopies)..where(
              (t) =>
                  t.contentHash.equals(contentHash) &
                  t.status.equals('verified'),
            ))
            .get();
    await (update(assetManifest)
          ..where((t) => t.contentHash.equals(contentHash)))
        .write(AssetManifestCompanion(copyCount: Value(copies.length)));
  }

  /// Mark local copy as verified with current timestamp.
  Future<void> markLocalVerified(String contentHash) =>
      updateLocalState(contentHash, localVerifiedAt: Value(DateTime.now()));

  /// Hard-delete a manifest entry (used by tombstone cleaner).
  Future<void> hardDelete(String contentHash) => (delete(
    assetManifest,
  )..where((t) => t.contentHash.equals(contentHash))).go();
}
