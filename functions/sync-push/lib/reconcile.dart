/// Pure, provider-neutral reconciliation core for the `sync-push` Appwrite
/// Function. Imports nothing from `dart_appwrite`, so the exact semantics —
/// last-writer-wins + tombstones + idempotency, ported from `convex/sync.ts`
/// (`pushRecords`) — are unit-testable against an in-memory [SyncStore] with no
/// live backend.
///
/// **Storage model** (differs from Convex's in-row soft-delete): a logical
/// record keyed by `(userId, id)` is in exactly one of two states —
/// **live** (a row in the descriptive table carrying `updatedAt`) or
/// **deleted** (a row in the shared `tombstones` table carrying `deletedAt`).
/// The monotonic LWW clock is whichever is present. This preserves Convex's
/// semantics one-for-one:
///   * a fresh upsert **un-tombstones** the record (Convex cleared `deletedAt`);
///   * a delete removes the live row and writes a tombstone (never a hard
///     delete of user state);
///   * reconciliation is `>=` — an incoming op applies unless the stored clock
///     is **strictly newer** (equal clocks apply, which makes replays no-ops).
///
/// `userId` is always the trusted `x-appwrite-user-id` the Function stamps, not
/// a client-supplied field — every store key is scoped to it (per-user rows).
library;

/// The descriptive last-writer-wins tables `sync-push` serves — the
/// `descriptiveTable` union from `convex/sync.ts` plus the two Appwrite-only
/// note-entry tables (task 4.9; never in the Convex era). `reviewEvents`
/// (append-only) and `fsrsCards` (server-derived) are handled elsewhere and
/// rejected here.
const Set<String> descriptiveTables = {
  'moves',
  'combos',
  'comboMoves',
  'decks',
  'deckMoves',
  'moveNoteEntries',
  'comboNoteEntries',
};

/// A client-authored upsert for one descriptive record. Wire shape mirrors
/// `convex/sync.ts` `recordArg`: `localId` + `json` + ms-epoch `updatedAt`.
class UpsertOp {
  const UpsertOp({
    required this.id,
    required this.json,
    required this.updatedAt,
    required this.clientOpId,
  });

  final String id;
  final Map<String, dynamic> json;
  final int updatedAt; // ms since epoch
  final String clientOpId;
}

/// A client-authored soft-delete. Wire shape mirrors `convex/sync.ts`
/// `tombstoneArg`: `localId` + ms-epoch `deletedAt`.
class TombstoneOp {
  const TombstoneOp({
    required this.id,
    required this.deletedAt,
    required this.clientOpId,
  });

  final String id;
  final int deletedAt; // ms since epoch
  final String clientOpId;
}

/// A batched push for one [table]. Parsed from the Function request body, whose
/// shape mirrors the Convex `sync:pushRecords` mutation args so the Dart client
/// transport marshals to it unchanged.
class PushRequest {
  const PushRequest({
    required this.table,
    required this.upserts,
    required this.deletes,
  });

  /// Parse and structurally validate the request body. Throws [PushRejection]
  /// (→ HTTP 400) on a malformed envelope or op; a client push is a trusted-
  /// shape contract, so a bad payload is the caller's error, not partial state.
  factory PushRequest.fromJson(final Map<String, dynamic> body) {
    final table = body['table'];
    if (table is! String || table.isEmpty) {
      throw const PushRejection('missing or invalid "table".');
    }
    return PushRequest(
      table: table,
      upserts: _asList(body['upserts']).map(_upsertFromJson).toList(),
      deletes: _asList(body['deletes']).map(_tombstoneFromJson).toList(),
    );
  }

  final String table;
  final List<UpsertOp> upserts;
  final List<TombstoneOp> deletes;
}

/// Outcome of applying a [PushRequest]: per-op counts. [failed] isolates a
/// store fault on one record from the rest of the batch (hardened-template
/// H.3), so a transient write error never aborts a whole push.
class PushResult {
  const PushResult({this.applied = 0, this.skipped = 0, this.failed = 0});

  final int applied;
  final int skipped;
  final int failed;
}

/// Raised when a table/op combination is not permitted (fsrsCard push,
/// reviewEvent delete, unknown table, malformed body). The Function maps it to
/// HTTP 400. It is an [Exception] (expected control flow), not an `Error`.
class PushRejection implements Exception {
  const PushRejection(this.message);

  final String message;

  @override
  String toString() => 'PushRejection: $message';
}

/// A stored row's LWW-relevant projection: an opaque [ref] the store uses to
/// address it for update/delete, plus its monotonic [clock] (ms epoch —
/// `updatedAt` for a live row, `deletedAt` for a tombstone).
class StoredRow {
  const StoredRow({required this.ref, required this.clock});

  final String ref;
  final int clock;
}

/// Persistence seam. The Function wires a `TablesDB`-backed implementation;
/// tests wire an in-memory fake. Every method is keyed by the trusted [userId].
abstract interface class SyncStore {
  Future<StoredRow?> getLive(
    final String table,
    final String userId,
    final String id,
  );

  Future<StoredRow?> getTombstone(
    final String table,
    final String userId,
    final String id,
  );

  Future<void> createLive(
    final String table, {
    required final String userId,
    required final String id,
    required final int updatedAt,
    required final String clientOpId,
    required final Map<String, dynamic> json,
  });

  Future<void> updateLive(
    final String table,
    final String ref, {
    required final int updatedAt,
    required final String clientOpId,
    required final Map<String, dynamic> json,
  });

  Future<void> deleteLive(final String table, final String ref);

  Future<void> createTombstone(
    final String table, {
    required final String userId,
    required final String id,
    required final int deletedAt,
    required final String clientOpId,
  });

  Future<void> updateTombstone(
    final String table,
    final String ref, {
    required final int deletedAt,
    required final String clientOpId,
  });

  Future<void> deleteTombstone(final String table, final String ref);
}

/// Validate the table, then apply every op with per-record store-fault
/// isolation. Returns applied/skipped/failed counts. Throws [PushRejection]
/// (before touching the store) for a forbidden table/op combination.
Future<PushResult> applyPush(
  final SyncStore store,
  final String userId,
  final PushRequest req, {
  final void Function(String message)? onError,
}) async {
  validatePushTable(req.table, hasDeletes: req.deletes.isNotEmpty);

  var applied = 0;
  var skipped = 0;
  var failed = 0;

  for (final op in req.upserts) {
    try {
      if (await _applyUpsert(store, req.table, userId, op)) {
        applied++;
      } else {
        skipped++;
      }
    } on Object catch (e) {
      failed++;
      onError?.call('upsert "${op.id}" failed: $e');
    }
  }
  for (final op in req.deletes) {
    try {
      if (await _applyDelete(store, req.table, userId, op)) {
        applied++;
      } else {
        skipped++;
      }
    } on Object catch (e) {
      failed++;
      onError?.call('delete "${op.id}" failed: $e');
    }
  }
  return PushResult(applied: applied, skipped: skipped, failed: failed);
}

/// Enforce the two named rejections (fsrsCard push, reviewEvent delete) plus
/// the general "only the five descriptive tables are pushable" rule. Matches
/// `convex/sync.ts`, whose `descriptiveTable` union excludes both — a Convex
/// validator would reject them identically.
void validatePushTable(final String table, {required final bool hasDeletes}) {
  if (table == 'fsrsCards') {
    throw const PushRejection(
      'fsrsCards is derived server-side from reviewEvents and can never be '
      'client-pushed.',
    );
  }
  if (table == 'reviewEvents') {
    throw PushRejection(
      hasDeletes
          ? 'reviewEvents is append-only; deletes are never permitted.'
          : 'reviewEvents must be appended via the reviews-append Function, '
                'not sync-push.',
    );
  }
  if (!descriptiveTables.contains(table)) {
    throw PushRejection('unsupported table: "$table".');
  }
}

/// Port of `pushRecords`' upsert arm. Returns whether the op applied.
Future<bool> _applyUpsert(
  final SyncStore store,
  final String table,
  final String userId,
  final UpsertOp op,
) async {
  final live = await store.getLive(table, userId, op.id);
  final tomb = await store.getTombstone(table, userId, op.id);
  final stored = _maxClock(live, tomb);

  if (stored == null) {
    await store.createLive(
      table,
      userId: userId,
      id: op.id,
      updatedAt: op.updatedAt,
      clientOpId: op.clientOpId,
      json: op.json,
    );
    return true;
  }
  if (op.updatedAt < stored) {
    return false; // stored clock strictly newer — skip
  }
  // op wins (>=): write the live state, clearing any tombstone (un-tombstone).
  if (live != null) {
    await store.updateLive(
      table,
      live.ref,
      updatedAt: op.updatedAt,
      clientOpId: op.clientOpId,
      json: op.json,
    );
  } else {
    await store.createLive(
      table,
      userId: userId,
      id: op.id,
      updatedAt: op.updatedAt,
      clientOpId: op.clientOpId,
      json: op.json,
    );
  }
  if (tomb != null) {
    await store.deleteTombstone(table, tomb.ref);
  }
  return true;
}

/// Port of `pushRecords`' delete arm. Returns whether the tombstone applied.
Future<bool> _applyDelete(
  final SyncStore store,
  final String table,
  final String userId,
  final TombstoneOp op,
) async {
  final live = await store.getLive(table, userId, op.id);
  final tomb = await store.getTombstone(table, userId, op.id);
  final stored = _maxClock(live, tomb);

  if (stored == null) {
    await store.createTombstone(
      table,
      userId: userId,
      id: op.id,
      deletedAt: op.deletedAt,
      clientOpId: op.clientOpId,
    );
    return true;
  }
  if (op.deletedAt < stored) {
    return false; // stored clock strictly newer — skip
  }
  // op wins (>=): remove the live row, write/refresh the tombstone.
  if (live != null) {
    await store.deleteLive(table, live.ref);
  }
  if (tomb != null) {
    await store.updateTombstone(
      table,
      tomb.ref,
      deletedAt: op.deletedAt,
      clientOpId: op.clientOpId,
    );
  } else {
    await store.createTombstone(
      table,
      userId: userId,
      id: op.id,
      deletedAt: op.deletedAt,
      clientOpId: op.clientOpId,
    );
  }
  return true;
}

/// The stored monotonic clock across the (mutually exclusive) live/tombstone
/// states. Defensive `max` in case an earlier fault left both present.
int? _maxClock(final StoredRow? live, final StoredRow? tomb) {
  if (live == null) {
    return tomb?.clock;
  }
  if (tomb == null) {
    return live.clock;
  }
  return live.clock > tomb.clock ? live.clock : tomb.clock;
}

// --- Body parsing helpers ---------------------------------------------------

List<dynamic> _asList(final Object? v) => v is List ? v : const [];

Map<String, dynamic> _asMap(final Object? v) =>
    v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};

UpsertOp _upsertFromJson(final Object? e) {
  final m = _asMap(e);
  return UpsertOp(
    id: _str(m['localId'], 'upsert.localId'),
    json: _asMap(m['json']),
    updatedAt: _int(m['updatedAt'], 'upsert.updatedAt'),
    clientOpId: _str(m['clientOpId'], 'upsert.clientOpId'),
  );
}

TombstoneOp _tombstoneFromJson(final Object? e) {
  final m = _asMap(e);
  return TombstoneOp(
    id: _str(m['localId'], 'delete.localId'),
    deletedAt: _int(m['deletedAt'], 'delete.deletedAt'),
    clientOpId: _str(m['clientOpId'], 'delete.clientOpId'),
  );
}

String _str(final Object? v, final String field) {
  if (v is String && v.isNotEmpty) {
    return v;
  }
  throw PushRejection('missing or invalid "$field".');
}

int _int(final Object? v, final String field) {
  if (v is int) {
    return v;
  }
  if (v is num) {
    return v.toInt();
  }
  throw PushRejection('missing or invalid "$field".');
}
