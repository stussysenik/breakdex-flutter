import 'package:drift/drift.dart';

/// Queue of pending and in-progress sync operations.
///
/// The sync engine processes this queue in priority order, handling uploads,
/// downloads, verifications, and remote deletions. Failed operations are
/// retried up to [maxRetries] times with exponential backoff.
class SyncOperations extends Table {
  /// UUID for this operation.
  TextColumn get id => text()();

  /// Content hash of the asset being operated on.
  TextColumn get contentHash => text()();

  /// Which provider this operation targets.
  TextColumn get providerId => text()();

  /// What the operation does: upload, download, verify, delete_remote.
  TextColumn get operationType => text()();

  /// Lifecycle: queued → in_progress → completed → failed.
  TextColumn get status =>
      text().withDefault(const Constant('queued'))();

  /// Higher priority operations are processed first.
  IntColumn get priority => integer().withDefault(const Constant(0))();

  /// How many times this operation has been retried.
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Maximum retry attempts before giving up.
  IntColumn get maxRetries => integer().withDefault(const Constant(3))();

  /// Error message from the last failed attempt.
  TextColumn get errorMessage => text().nullable()();

  /// Bytes transferred so far (for progress tracking).
  IntColumn get bytesTransferred =>
      integer().withDefault(const Constant(0))();

  /// Total bytes to transfer (for progress calculation).
  IntColumn get totalBytes => integer().withDefault(const Constant(0))();

  /// When this operation was queued.
  DateTimeColumn get createdAt => dateTime()();

  /// When processing started.
  DateTimeColumn get startedAt => dateTime().nullable()();

  /// When the operation completed (successfully or after final failure).
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
