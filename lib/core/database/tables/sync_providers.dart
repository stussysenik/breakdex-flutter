import 'package:drift/drift.dart';

/// Configuration for cloud storage providers.
///
/// Each row represents a configured provider (iCloud, Google Drive, S3, etc.)
/// with its auth state, quota, and user-facing display name. Provider-specific
/// configuration (bucket name, endpoint URL) is stored as encrypted JSON.
class SyncProviders extends Table {
  /// UUID for this provider configuration.
  TextColumn get id => text()();

  /// Provider type identifier: icloud, gdrive, s3.
  TextColumn get providerType => text()();

  /// User-facing display name (e.g. "My Google Drive", "Work S3 Bucket").
  TextColumn get displayName => text()();

  /// Whether this provider is active for sync operations.
  BoolColumn get enabled =>
      boolean().withDefault(const Constant(true))();

  /// Provider-specific configuration as JSON (e.g. bucket name, endpoint).
  TextColumn get configJson => text().nullable()();

  /// Total storage quota in bytes (null if unknown/unlimited).
  IntColumn get quotaBytes => integer().nullable()();

  /// Used storage in bytes (null if unknown).
  IntColumn get usedBytes => integer().nullable()();

  /// Last successful authentication timestamp.
  DateTimeColumn get lastAuthAt => dateTime().nullable()();

  /// When this provider was first configured.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
