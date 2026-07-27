import 'package:drift/drift.dart';

import 'package:breakdex/core/database/tables/asset_manifest.dart';

/// Tracks each copy of a video asset across storage providers.
///
/// A single video (identified by [contentHash]) can have multiple copies:
/// one local, plus one per cloud provider. The sync engine uses this table
/// to enforce the two-copy minimum before allowing local deletion.
class AssetCopies extends Table {
  /// UUID for this copy record.
  TextColumn get id => text()();

  /// FK to [AssetManifest.contentHash] — which asset this copy belongs to.
  TextColumn get contentHash =>
      text().references(AssetManifest, #contentHash)();

  /// Storage provider: local, icloud, gdrive, s3.
  TextColumn get provider => text()();

  /// Provider-specific path or key (e.g. iCloud container path, S3 object key).
  TextColumn get remotePath => text().nullable()();

  /// Provider-specific etag or version identifier for cache invalidation.
  TextColumn get remoteEtag => text().nullable()();

  /// Last time this copy was verified to exist and match [contentHash].
  DateTimeColumn get verifiedAt => dateTime().nullable()();

  /// Copy lifecycle: pending → uploading → verified → failed → deleted.
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  /// Upload/download progress as a fraction (0.0–1.0).
  RealColumn get uploadProgress => real().nullable()();

  /// Last error message if status is 'failed'.
  TextColumn get errorMessage => text().nullable()();

  /// When this copy record was created.
  DateTimeColumn get createdAt => dateTime()();

  /// When this copy record was last updated.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
