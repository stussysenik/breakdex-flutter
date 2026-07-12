/// Combo / ComboMove ⇄ [SyncRecord] codecs — the provider-neutral
/// (de)serialization for the `combos` and `comboMoves` entities (task 4.4),
/// shared by the backfill (encode) and the dual-read merge (decode). Modeled on
/// `move_codec.dart`: each encode/decode pair is exact inverses, and every
/// [DateTime] round-trips as ms-since-epoch.
///
/// `combos` + `comboMoves` sync as **two distinct entities** (their own
/// [SyncEntityType]s and Appwrite tables), so this file carries a codec for
/// each. Video *bytes* never appear here; `activeVideoPath`/`contentHash` are
/// pointers.
library;

import 'package:drift/drift.dart';

import '../../database/database.dart';
import '../sync_backend.dart';

/// Never-null-clock guard for a corrupt row whose `updatedAt` is somehow null
/// (unreachable post-v24-migration + DAO stamping). Epoch-0 is the
/// oldest-possible clock, so such a row can be overwritten by anything and
/// never clobbers a real edit — the data-safe degenerate behavior.
final DateTime _epochGuard = DateTime.fromMillisecondsSinceEpoch(
  0,
  isUtc: true,
);

/// Project a [Combo] onto its provider-neutral [SyncRecord].
SyncRecord comboToSyncRecord(final Combo c) => SyncRecord(
  id: c.id,
  type: SyncEntityType.combo,
  json: comboToSyncJson(c),
  // Post-v24 every row has updatedAt; fall back to createdAt defensively so a
  // pre-migration row can never push a null clock.
  updatedAt: c.updatedAt ?? c.createdAt,
  clientOpId: 'backfill:combo:${c.id}',
);

/// The JSON-safe descriptive payload for a combo (see [comboToSyncRecord]).
Map<String, Object?> comboToSyncJson(final Combo c) => {
  'name': c.name,
  'notes': c.notes,
  'activeVideoPath': c.activeVideoPath,
  'contentHash': c.contentHash,
  'status': c.status,
  'createdAt': c.createdAt.millisecondsSinceEpoch,
};

/// Decode a pulled combo [record] back into a [CombosCompanion] — the exact
/// inverse of [comboToSyncJson]. Identity ([SyncRecord.id]) and the LWW clock
/// ([SyncRecord.updatedAt]) live outside `json`, mirroring the split in
/// [comboToSyncRecord].
CombosCompanion comboFromSyncRecord(final SyncRecord record) {
  final json = record.json;
  return CombosCompanion(
    id: Value(record.id),
    name: Value(json['name'] as String),
    notes: Value(json['notes'] as String?),
    activeVideoPath: Value(json['activeVideoPath'] as String?),
    contentHash: Value(json['contentHash'] as String?),
    status: Value(json['status'] as String? ?? 'idea'),
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

/// Project a [ComboMove] onto its provider-neutral [SyncRecord].
SyncRecord comboMoveToSyncRecord(final ComboMove cm) => SyncRecord(
  id: cm.id,
  type: SyncEntityType.comboMove,
  json: comboMoveToSyncJson(cm),
  // combo_moves has no createdAt; v24 + DAO stamping guarantee updatedAt, and
  // the epoch guard covers only a genuinely-corrupt row (see [_epochGuard]).
  updatedAt: cm.updatedAt ?? _epochGuard,
  clientOpId: 'backfill:comboMove:${cm.id}',
);

/// The JSON-safe payload for a combo step (see [comboMoveToSyncRecord]).
Map<String, Object?> comboMoveToSyncJson(final ComboMove cm) => {
  'comboId': cm.comboId,
  'moveId': cm.moveId,
  'sequenceIndex': cm.sequenceIndex,
  'count': cm.count,
};

/// Decode a pulled combo-step [record] back into a [ComboMovesCompanion] — the
/// exact inverse of [comboMoveToSyncJson].
ComboMovesCompanion comboMoveFromSyncRecord(final SyncRecord record) {
  final json = record.json;
  return ComboMovesCompanion(
    id: Value(record.id),
    comboId: Value(json['comboId'] as String),
    moveId: Value(json['moveId'] as String),
    sequenceIndex: Value((json['sequenceIndex'] as num).toInt()),
    count: Value((json['count'] as num?)?.toInt() ?? 1),
    updatedAt: Value(record.updatedAt),
  );
}
