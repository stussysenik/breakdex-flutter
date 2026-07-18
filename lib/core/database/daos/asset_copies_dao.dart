import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/asset_copies.dart';

part 'asset_copies_dao.g.dart';

@DriftAccessor(tables: [AssetCopies])
class AssetCopiesDao extends DatabaseAccessor<AppDatabase>
    with _$AssetCopiesDaoMixin {
  AssetCopiesDao(super.db);

  /// The identity of a copy is `(contentHash, provider)` — one asset has at
  /// most one copy per provider (design D7). Deriving the row id from that
  /// pair is what makes [upsertCopy] actually upsert; before this, every write
  /// site minted its own id (a fresh UUID in the sync engine, four different
  /// `_local` schemes elsewhere), so re-uploads appended duplicate rows and
  /// `copyCount` overstated protection — the two-copy minimum that gates local
  /// deletion could be satisfied by one real cloud copy.
  ///
  /// A unique index on `(content_hash, provider)` enforces the same invariant
  /// at the storage layer; see `_installAssetCopyIdentityIndex`.
  static String copyId(final String contentHash, final String provider) =>
      '${contentHash}_$provider';

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// All copies for a given content hash, ordered by provider.
  Future<List<AssetCopy>> getByHash(final String contentHash) =>
      (select(assetCopies)
            ..where((final t) => t.contentHash.equals(contentHash))
            ..orderBy([(final t) => OrderingTerm.asc(t.provider)]))
          .get();

  Stream<List<AssetCopy>> watchByHash(final String contentHash) =>
      (select(assetCopies)
            ..where((final t) => t.contentHash.equals(contentHash))
            ..orderBy([(final t) => OrderingTerm.asc(t.provider)]))
          .watch();

  /// Get the local copy for an asset (provider = 'local').
  Future<AssetCopy?> getLocalCopy(final String contentHash) =>
      (select(assetCopies)
            ..where((final t) =>
                t.contentHash.equals(contentHash) &
                t.provider.equals('local')))
          .getSingleOrNull();

  /// Count verified copies for a given asset.
  Future<int> countVerified(final String contentHash) async {
    final count = assetCopies.id.count();
    final query = selectOnly(assetCopies)
      ..addColumns([count])
      ..where(assetCopies.contentHash.equals(contentHash) &
          assetCopies.status.equals('verified'));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Copies currently uploading (for progress UI).
  Stream<List<AssetCopy>> watchUploading() =>
      (select(assetCopies)
            ..where((final t) => t.status.equals('uploading'))
            ..orderBy([(final t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  /// All copies for a given provider.
  Future<List<AssetCopy>> getByProvider(final String provider) =>
      (select(assetCopies)
            ..where((final t) => t.provider.equals(provider)))
          .get();

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  Future<void> insertCopy(final AssetCopiesCompanion entry) =>
      into(assetCopies).insert(entry);

  Future<void> upsertCopy(final AssetCopiesCompanion entry) =>
      into(assetCopies).insertOnConflictUpdate(entry);

  Future<void> updateCopy(final AssetCopiesCompanion entry) =>
      (update(assetCopies)..where((final t) => t.id.equals(entry.id.value)))
          .write(entry);

  /// Mark a copy as verified with the current timestamp.
  Future<void> markVerified(final String id, {final String? etag}) =>
      (update(assetCopies)..where((final t) => t.id.equals(id))).write(
        AssetCopiesCompanion(
          status: const Value('verified'),
          verifiedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
          remoteEtag: etag != null ? Value(etag) : const Value.absent(),
        ),
      );

  /// Mark a copy as failed with an error message.
  Future<void> markFailed(final String id, final String errorMessage) =>
      (update(assetCopies)..where((final t) => t.id.equals(id))).write(
        AssetCopiesCompanion(
          status: const Value('failed'),
          errorMessage: Value(errorMessage),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Update upload progress for a copy.
  Future<void> updateProgress(final String id, final double progress) =>
      (update(assetCopies)..where((final t) => t.id.equals(id))).write(
        AssetCopiesCompanion(
          uploadProgress: Value(progress),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Delete all copies for a content hash (used by tombstone cleaner).
  Future<void> deleteByHash(final String contentHash) =>
      (delete(assetCopies)
            ..where((final t) => t.contentHash.equals(contentHash)))
          .go();

  /// Delete a single copy by ID.
  Future<void> deleteCopy(final String id) =>
      (delete(assetCopies)..where((final t) => t.id.equals(id))).go();
}
