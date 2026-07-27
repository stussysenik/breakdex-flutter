/// Deck / DeckMove ⇄ [SyncRecord] codecs — the provider-neutral (de)serialization
/// for the `decks` and `deckMoves` entities (task 4.7), shared by the backfill
/// (encode) and the dual-read merge (decode). Modeled on `combo_codec.dart`:
/// each encode/decode pair is exact inverses, and every [DateTime] round-trips
/// as ms-since-epoch.
///
/// **Appwrite-only (D11).** Unlike moves/combos, decks have *no* Firestore
/// legacy — they were never in the Firestore metadata sync, only the on-device
/// Drive manifest. So this codec serves the Appwrite path exclusively; there is
/// no dual-write ladder to reconcile against, only the same LWW + tombstone +
/// `clientOpId` semantics.
///
/// **`deckMoves` has no `id` column.** The join is keyed by the composite PK
/// `(deckId, moveId)`, so its wire identity is the composite `'$deckId:$moveId'`
/// (deckIds/moveIds are UUIDv4 — colon-free — so the split is unambiguous). The
/// decode reads `deckId`/`moveId` from `json`, never by parsing the id, so the
/// backend id is opaque to reconstruction.
library;

import 'package:drift/drift.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/sync/sync_backend.dart';

/// Never-null-clock guard for a corrupt row whose `updatedAt` is somehow null
/// (unreachable post-v25-migration + DAO stamping). Epoch-0 is the
/// oldest-possible clock, so such a row never clobbers a real edit.
final DateTime _epochGuard = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

/// The composite wire id for a deck-move join row — its natural key, since the
/// table has no synthetic `id`.
String deckMoveWireId(final String deckId, final String moveId) =>
    '$deckId:$moveId';

/// Project a [Deck] onto its provider-neutral [SyncRecord].
SyncRecord deckToSyncRecord(final Deck d) => SyncRecord(
  id: d.id,
  type: SyncEntityType.deck,
  json: deckToSyncJson(d),
  // `decks.updatedAt` is non-null (defaulted since the original schema); fall
  // back to createdAt purely defensively.
  updatedAt: d.updatedAt,
  clientOpId: 'backfill:deck:${d.id}',
);

/// The JSON-safe descriptive payload for a deck (see [deckToSyncRecord]).
Map<String, Object?> deckToSyncJson(final Deck d) => {
  'name': d.name,
  'deckType': d.deckType,
  'filterCriteria': d.filterCriteria,
  'sessionSize': d.sessionSize,
  'createdAt': d.createdAt.millisecondsSinceEpoch,
};

/// Decode a pulled deck [record] back into a [DecksCompanion] — the exact
/// inverse of [deckToSyncJson]. Identity and the LWW clock live outside `json`.
DecksCompanion deckFromSyncRecord(final SyncRecord record) {
  final json = record.json;
  return DecksCompanion(
    id: Value(record.id),
    name: Value(json['name'] as String),
    deckType: Value(json['deckType'] as String? ?? 'smart'),
    filterCriteria: Value(json['filterCriteria'] as String?),
    sessionSize: Value((json['sessionSize'] as num?)?.toInt()),
    createdAt: Value(
      DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num).toInt(),
        isUtc: true,
      ),
    ),
    // Preserve the remote LWW clock verbatim — a direct upsert (not the DAO) so
    // it is never re-stamped to now(), which would loop the record back out.
    updatedAt: Value(record.updatedAt),
  );
}

/// Project a [DeckMove] onto its provider-neutral [SyncRecord]. The id is the
/// composite `(deckId, moveId)` (the table has no synthetic id).
SyncRecord deckMoveToSyncRecord(final DeckMove dm) => SyncRecord(
  id: deckMoveWireId(dm.deckId, dm.moveId),
  type: SyncEntityType.deckMove,
  json: deckMoveToSyncJson(dm),
  // deck_moves has no createdAt; v25 + DAO stamping guarantee updatedAt, and the
  // epoch guard covers only a genuinely-corrupt row (see [_epochGuard]).
  updatedAt: dm.updatedAt ?? _epochGuard,
  clientOpId: 'backfill:deckMove:${dm.deckId}:${dm.moveId}',
);

/// The JSON-safe payload for a deck-move join (see [deckMoveToSyncRecord]).
Map<String, Object?> deckMoveToSyncJson(final DeckMove dm) => {
  'deckId': dm.deckId,
  'moveId': dm.moveId,
};

/// Decode a pulled deck-move [record] back into a [DeckMovesCompanion] — the
/// exact inverse of [deckMoveToSyncJson]. Identity comes from `json` (deckId +
/// moveId), never by parsing the composite [SyncRecord.id].
DeckMovesCompanion deckMoveFromSyncRecord(final SyncRecord record) {
  final json = record.json;
  return DeckMovesCompanion(
    deckId: Value(json['deckId'] as String),
    moveId: Value(json['moveId'] as String),
    updatedAt: Value(record.updatedAt),
  );
}
