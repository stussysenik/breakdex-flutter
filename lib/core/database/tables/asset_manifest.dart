import 'package:drift/drift.dart';

/// Content-addressable manifest for all video assets.
///
/// Each unique video file gets one row keyed by its SHA-256 hash. This enables
/// deduplication (same video imported twice = same row) and integrity
/// verification (re-hash → compare). The [localPath] points to the current
/// on-disk location; cloud copies live in [AssetCopies].
class AssetManifest extends Table {
  /// SHA-256 hex digest of the file contents — serves as the primary key.
  TextColumn get contentHash => text()();

  /// File size in bytes at import time.
  IntColumn get fileSizeBytes => integer()();

  /// MIME type, defaults to video/mp4 for breakdance training clips.
  TextColumn get mimeType =>
      text().withDefault(const Constant('video/mp4'))();

  /// Video duration in milliseconds (populated from metadata when available).
  IntColumn get durationMs => integer().nullable()();

  /// Video width in pixels.
  IntColumn get width => integer().nullable()();

  /// Video height in pixels.
  IntColumn get height => integer().nullable()();

  /// Path to the local copy **relative to the Documents directory** (null if
  /// the asset only exists in the cloud). Never absolute: iOS rewrites the
  /// container UUID on every reinstall, so an absolute path is dead on the
  /// next launch — resolve through `VideoPathResolver.toAbsolute`.
  ///
  /// A *hint*, not identity. It is written at import and goes stale on
  /// renames and category moves; the sync engine heals it (owning entity,
  /// then a hash-indexed sandbox scan) and writes the correction back here.
  TextColumn get localPath => text().nullable()();

  /// Last time the local file was verified to match [contentHash].
  DateTimeColumn get localVerifiedAt => dateTime().nullable()();

  /// How this asset entered the library.
  /// Values: camera, photos, files, cloud_download, legacy_migration
  TextColumn get sourceType => text()();

  /// Human-readable source name (e.g. original filename, album name).
  TextColumn get sourceName => text().nullable()();

  /// When this asset was first imported into the library.
  DateTimeColumn get importedAt => dateTime()();

  /// Soft-delete timestamp. Non-null means the asset is in the "trash".
  /// The file is retained for a 30-day grace period before hard deletion.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Why the asset was soft-deleted: user, replaced, corrupted.
  TextColumn get tombstoneReason => text().nullable()();

  /// Number of verified copies (local + cloud). Must be >= 2 before local
  /// deletion is permitted.
  IntColumn get copyCount => integer().withDefault(const Constant(1))();

  /// Last time any copy was synced to a cloud provider.
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {contentHash};
}
