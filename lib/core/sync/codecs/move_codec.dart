/// Move ⇄ [SyncRecord] codec — the provider-neutral (de)serialization for the
/// `moves` entity, shared by the backfill (encode) and the dual-read merge
/// (decode). Extracted from `sync_backfill_service.dart` (task H.5) as the
/// template layout that combos/reviews/decks replicate under `codecs/`.
///
/// The encode/decode pair is exact inverses; the BigInt/DateTime round-trip is
/// proven by the codec's own test.
library;

import 'package:drift/drift.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/sync/sync_backend.dart';

/// Project a [Move] onto its provider-neutral [SyncRecord].
///
/// The payload is JSON-safe by construction (the HTTP transport `jsonEncode`s
/// it): every field is a String / num / bool / null. In particular
/// [Move.videoFileSize] is a `BigInt` — not JSON-encodable and lossy past 2^53
/// as a JS number — so it is carried as a lossless decimal string, and every
/// [DateTime] is carried as ms-since-epoch. Video *bytes* never appear here;
/// `videoPath`/`contentHash` are pointers.
SyncRecord moveToSyncRecord(final Move m) => SyncRecord(
  id: m.id,
  type: SyncEntityType.move,
  json: moveToSyncJson(m),
  // Post-v23 every row has updatedAt; fall back to createdAt defensively so a
  // pre-migration row can never push a null clock.
  updatedAt: m.updatedAt ?? m.createdAt,
  clientOpId: 'backfill:move:${m.id}',
);

/// The JSON-safe descriptive payload for a move (see [moveToSyncRecord]).
Map<String, Object?> moveToSyncJson(final Move m) => {
  'name': m.name,
  'learningState': m.learningState,
  'category': m.category,
  'videoPath': m.videoPath,
  'originalVideoName': m.originalVideoName,
  'managedAlbumAssetId': m.managedAlbumAssetId,
  'managedAlbumFilename': m.managedAlbumFilename,
  'managedAlbumName': m.managedAlbumName,
  'notes': m.notes,
  'imagePaths': m.imagePaths,
  'contentHash': m.contentHash,
  'count': m.count,
  'videoFileSize': m.videoFileSize?.toString(),
  'archivedAt': m.archivedAt?.millisecondsSinceEpoch,
  'archiveReason': m.archiveReason,
  'videoCreationDate': m.videoCreationDate?.millisecondsSinceEpoch,
  'createdAt': m.createdAt.millisecondsSinceEpoch,
};

/// Decode a pulled move [record] back into a [MovesCompanion] — the exact
/// inverse of [moveToSyncJson], used by the task 2.1 dual-read merge.
///
/// [SyncRecord.id] carries identity and [SyncRecord.updatedAt] carries the
/// last-writer-wins clock (neither lives in [SyncRecord.json], mirroring how
/// [moveToSyncRecord] splits them out). Every field is reconstructed at full
/// fidelity: `videoFileSize` parses back from its lossless decimal string into
/// a [BigInt], and every ms-since-epoch int becomes a UTC [DateTime].
MovesCompanion moveFromSyncRecord(final SyncRecord record) {
  final json = record.json;
  DateTime? epochMs(final Object? v) => v == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch((v as num).toInt(), isUtc: true);
  return MovesCompanion(
    id: Value(record.id),
    name: Value(json['name'] as String),
    learningState: Value(json['learningState'] as String),
    category: Value(json['category'] as String),
    videoPath: Value(json['videoPath'] as String?),
    originalVideoName: Value(json['originalVideoName'] as String?),
    managedAlbumAssetId: Value(json['managedAlbumAssetId'] as String?),
    managedAlbumFilename: Value(json['managedAlbumFilename'] as String?),
    managedAlbumName: Value(json['managedAlbumName'] as String?),
    notes: Value(json['notes'] as String?),
    imagePaths: Value(json['imagePaths'] as String?),
    contentHash: Value(json['contentHash'] as String?),
    count: Value((json['count'] as num?)?.toInt() ?? 4),
    videoFileSize: Value(
      json['videoFileSize'] == null
          ? null
          : BigInt.parse(json['videoFileSize'] as String),
    ),
    archivedAt: Value(epochMs(json['archivedAt'])),
    archiveReason: Value(json['archiveReason'] as String?),
    videoCreationDate: Value(epochMs(json['videoCreationDate'])),
    createdAt: Value(epochMs(json['createdAt'])!),
    // Preserve the remote LWW clock verbatim — a direct upsert (not the DAO)
    // so it is never re-stamped to now(), which would loop the record back out.
    updatedAt: Value(record.updatedAt),
  );
}
