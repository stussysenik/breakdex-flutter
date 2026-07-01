import 'package:drift/drift.dart';

class Moves extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1)();
  TextColumn get learningState => text().withDefault(const Constant('NEW'))();
  TextColumn get category => text().withDefault(const Constant('default'))();
  TextColumn get videoPath => text().nullable()();
  TextColumn get originalVideoName => text().nullable()();
  TextColumn get managedAlbumAssetId => text().nullable()();
  TextColumn get managedAlbumFilename => text().nullable()();
  TextColumn get managedAlbumName => text().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  TextColumn get archiveReason => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get imagePaths => text().nullable()();
  TextColumn get contentHash => text().nullable()();
  IntColumn get count => integer().withDefault(const Constant(4))();
  Int64Column get videoFileSize => int64().nullable()();
  DateTimeColumn get videoCreationDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last local mutation time — the monotonic clock the Convex sync backend
  /// uses for last-writer-wins reconciliation. Bumped by [MovesDao] on every
  /// user edit; a reconcile write preserves the remote timestamp instead.
  /// Nullable so the additive v23 migration can backfill it to [createdAt].
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
