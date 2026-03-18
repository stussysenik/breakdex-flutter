import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/asset_copies.dart';

part 'asset_copies_dao.g.dart';

@DriftAccessor(tables: [AssetCopies])
class AssetCopiesDao extends DatabaseAccessor<AppDatabase>
    with _$AssetCopiesDaoMixin {
  AssetCopiesDao(super.db);

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// All copies for a given content hash, ordered by provider.
  Future<List<AssetCopy>> getByHash(String contentHash) =>
      (select(assetCopies)
            ..where((t) => t.contentHash.equals(contentHash))
            ..orderBy([(t) => OrderingTerm.asc(t.provider)]))
          .get();

  Stream<List<AssetCopy>> watchByHash(String contentHash) =>
      (select(assetCopies)
            ..where((t) => t.contentHash.equals(contentHash))
            ..orderBy([(t) => OrderingTerm.asc(t.provider)]))
          .watch();

  /// Get the local copy for an asset (provider = 'local').
  Future<AssetCopy?> getLocalCopy(String contentHash) =>
      (select(assetCopies)
            ..where((t) =>
                t.contentHash.equals(contentHash) &
                t.provider.equals('local')))
          .getSingleOrNull();

  /// Count verified copies for a given asset.
  Future<int> countVerified(String contentHash) async {
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
            ..where((t) => t.status.equals('uploading'))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  /// All copies for a given provider.
  Future<List<AssetCopy>> getByProvider(String provider) =>
      (select(assetCopies)
            ..where((t) => t.provider.equals(provider)))
          .get();

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  Future<void> insertCopy(AssetCopiesCompanion entry) =>
      into(assetCopies).insert(entry);

  Future<void> upsertCopy(AssetCopiesCompanion entry) =>
      into(assetCopies).insertOnConflictUpdate(entry);

  Future<void> updateCopy(AssetCopiesCompanion entry) =>
      (update(assetCopies)..where((t) => t.id.equals(entry.id.value)))
          .write(entry);

  /// Mark a copy as verified with the current timestamp.
  Future<void> markVerified(String id, {String? etag}) =>
      (update(assetCopies)..where((t) => t.id.equals(id))).write(
        AssetCopiesCompanion(
          status: const Value('verified'),
          verifiedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
          remoteEtag: etag != null ? Value(etag) : const Value.absent(),
        ),
      );

  /// Mark a copy as failed with an error message.
  Future<void> markFailed(String id, String errorMessage) =>
      (update(assetCopies)..where((t) => t.id.equals(id))).write(
        AssetCopiesCompanion(
          status: const Value('failed'),
          errorMessage: Value(errorMessage),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Update upload progress for a copy.
  Future<void> updateProgress(String id, double progress) =>
      (update(assetCopies)..where((t) => t.id.equals(id))).write(
        AssetCopiesCompanion(
          uploadProgress: Value(progress),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Delete all copies for a content hash (used by tombstone cleaner).
  Future<void> deleteByHash(String contentHash) =>
      (delete(assetCopies)
            ..where((t) => t.contentHash.equals(contentHash)))
          .go();

  /// Delete a single copy by ID.
  Future<void> deleteCopy(String id) =>
      (delete(assetCopies)..where((t) => t.id.equals(id))).go();
}
