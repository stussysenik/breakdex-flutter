/// MoveNoteEntry / ComboNoteEntry ⇄ [SyncRecord] codecs — the provider-neutral
/// (de)serialization for the `moveNoteEntries` and `comboNoteEntries` entities
/// (task 4.9), shared by the backfill (encode) and the dual-read merge (decode).
/// Modeled on `deck_codec.dart`: each encode/decode pair is exact inverses, and
/// every [DateTime] round-trips as ms-since-epoch.
///
/// **Appwrite-only (D11).** Note entries have *no* Firestore legacy — they were
/// device-only until this task. So these codecs serve the Appwrite path
/// exclusively; there is no dual-write ladder to reconcile against, only the
/// same LWW + tombstone + `clientOpId` semantics. The single `notes` COLUMN on
/// moves/combos already rides inside those entities' payloads — this codec is
/// the multi-entry note tables.
///
/// Both tables carry a synthetic `id`, so the wire identity is that `id`
/// directly (unlike `deckMoves`' composite key). The LWW clock and identity
/// live outside `json`; the payload is the descriptive body only.
library;

import 'package:drift/drift.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/sync/sync_backend.dart';

/// Project a [MoveNoteEntry] onto its provider-neutral [SyncRecord]. The LWW
/// clock falls back to `createdAt` for a (post-v27-migration unreachable) null
/// `updatedAt`, so such a row never clobbers a real edit.
SyncRecord moveNoteEntryToSyncRecord(final MoveNoteEntry n) => SyncRecord(
  id: n.id,
  type: SyncEntityType.moveNoteEntry,
  json: moveNoteEntryToSyncJson(n),
  updatedAt: n.updatedAt ?? n.createdAt,
  clientOpId: 'backfill:moveNoteEntry:${n.id}',
);

/// The JSON-safe descriptive payload for a move note entry.
Map<String, Object?> moveNoteEntryToSyncJson(final MoveNoteEntry n) => {
  'moveId': n.moveId,
  'body': n.body,
  'createdAt': n.createdAt.millisecondsSinceEpoch,
};

/// Decode a pulled move note [record] back into a [MoveNoteEntriesCompanion] —
/// the exact inverse of [moveNoteEntryToSyncJson]. Identity and the LWW clock
/// live outside `json`; the remote clock is preserved verbatim (a direct upsert,
/// not the DAO) so it is never re-stamped to now() and looped back out.
MoveNoteEntriesCompanion moveNoteEntryFromSyncRecord(final SyncRecord record) {
  final json = record.json;
  return MoveNoteEntriesCompanion(
    id: Value(record.id),
    moveId: Value(json['moveId'] as String),
    body: Value(json['body'] as String),
    createdAt: Value(
      DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num).toInt(),
        isUtc: true,
      ),
    ),
    updatedAt: Value(record.updatedAt),
  );
}

/// Project a [ComboNoteEntry] onto its provider-neutral [SyncRecord]. Combo note
/// entries carry the `kind` tag + optional video reference alongside the body.
SyncRecord comboNoteEntryToSyncRecord(final ComboNoteEntry n) => SyncRecord(
  id: n.id,
  type: SyncEntityType.comboNoteEntry,
  json: comboNoteEntryToSyncJson(n),
  updatedAt: n.updatedAt ?? n.createdAt,
  clientOpId: 'backfill:comboNoteEntry:${n.id}',
);

/// The JSON-safe descriptive payload for a combo note entry. Nullable video
/// fields are omitted when absent so the wire stays minimal; the decode reads
/// them back as null.
Map<String, Object?> comboNoteEntryToSyncJson(final ComboNoteEntry n) => {
  'comboId': n.comboId,
  'body': n.body,
  'kind': n.kind,
  'videoPath': n.videoPath,
  'videoHash': n.videoHash,
  'createdAt': n.createdAt.millisecondsSinceEpoch,
};

/// Decode a pulled combo note [record] back into a [ComboNoteEntriesCompanion] —
/// the exact inverse of [comboNoteEntryToSyncJson].
ComboNoteEntriesCompanion comboNoteEntryFromSyncRecord(final SyncRecord record) {
  final json = record.json;
  return ComboNoteEntriesCompanion(
    id: Value(record.id),
    comboId: Value(json['comboId'] as String),
    body: Value(json['body'] as String),
    kind: Value(json['kind'] as String? ?? 'jot'),
    videoPath: Value(json['videoPath'] as String?),
    videoHash: Value(json['videoHash'] as String?),
    createdAt: Value(
      DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num).toInt(),
        isUtc: true,
      ),
    ),
    updatedAt: Value(record.updatedAt),
  );
}
