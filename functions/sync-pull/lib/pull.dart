/// Pure, provider-neutral pull-delta core for the `sync-pull` Appwrite
/// Function. Imports nothing from `dart_appwrite`, so the exact semantics —
/// the delta shape + high-water cursor ported from `convex/sync.ts`
/// (`pullRecords`) — are unit-testable against an in-memory [PullStore] with no
/// live backend, mirroring the split used by `sync-push`.
///
/// **Storage model** (differs from Convex's single-table, in-row soft-delete):
/// a logical record keyed by `(userId, id)` is in exactly one of two states —
/// **live** (a descriptive-table row carrying `updatedAt`) or **deleted** (a
/// row in the shared `tombstones` table carrying `deletedAt`). Convex's
/// `pullRecords` read one table and split on `deletedAt`; here the pull reads
/// both and **unions** them, treating each state's timestamp as the same
/// monotonic clock. This is faithful because Convex's delete arm stamps
/// `updatedAt = deletedAt` on the tombstoned row, so in Convex a deleted row's
/// cursor clock already *was* its `deletedAt` — the two-table `deletedAt` plays
/// the identical role.
///
/// The returned **cursor** is the backend's per-entity high-water mark: the max
/// clock across every row in the delta (or the passed `since` when nothing
/// changed). The client persists it verbatim and passes it back as `since` on
/// the next pull — a server-owned cursor, never the shared client clock
/// (closes audit A2 / the D9 rollback + clock-skew hole).
///
/// `userId` is always the trusted `x-appwrite-user-id` the Function stamps, not
/// a client-supplied field — every store read is scoped to it (per-user rows).
library;

/// The descriptive tables `sync-pull` serves — the `descriptiveTable` union from
/// `convex/sync.ts` plus the two Appwrite-only note-entry tables (task 4.9).
/// `reviewEvents` (append-only) and `fsrsCards` (server-derived) are pulled via
/// their own Functions and rejected here.
const Set<String> descriptiveTables = {
  'moves',
  'combos',
  'comboMoves',
  'decks',
  'deckMoves',
  'moveNoteEntries',
  'comboNoteEntries',
};

/// A live descriptive record, already decoded (the stored `payload` JSON string
/// → [json] map) by the store. The pure core never touches encoding.
class LiveRecord {
  const LiveRecord({
    required this.id,
    required this.json,
    required this.updatedAt,
    required this.clientOpId,
  });

  final String id;
  final Map<String, dynamic> json;
  final int updatedAt; // ms since epoch — the live LWW clock
  final String clientOpId;
}

/// A tombstone record. `deletedAt` is the delete-state clock — the same logical
/// monotonic clock as a live row's `updatedAt`.
class TombstoneRecord {
  const TombstoneRecord({
    required this.id,
    required this.deletedAt,
    required this.clientOpId,
  });

  final String id;
  final int deletedAt; // ms since epoch — the delete LWW clock
  final String clientOpId;
}

/// A pulled upsert. Wire shape mirrors `convex/sync.ts` `pullRecords`' upsert
/// element so the Dart client transport unmarshals it unchanged.
class PullUpsert {
  const PullUpsert({
    required this.id,
    required this.json,
    required this.updatedAt,
    required this.clientOpId,
  });

  final String id;
  final Map<String, dynamic> json;
  final int updatedAt;
  final String clientOpId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'json': json,
    'updatedAt': updatedAt,
    'clientOpId': clientOpId,
  };
}

/// A pulled delete. Wire shape mirrors `pullRecords`' delete element.
class PullDelete {
  const PullDelete({
    required this.id,
    required this.deletedAt,
    required this.clientOpId,
  });

  final String id;
  final int deletedAt;
  final String clientOpId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'deletedAt': deletedAt,
    'clientOpId': clientOpId,
  };
}

/// The pull response: the delta plus the high-water [cursor]. Wire shape mirrors
/// `pullRecords`' return — `cursor` is `null` when nothing changed and no
/// `since` was supplied (a full pull of an empty entity).
class PullDelta {
  const PullDelta({
    required this.upserts,
    required this.deletes,
    required this.cursor,
  });

  final List<PullUpsert> upserts;
  final List<PullDelete> deletes;
  final int? cursor;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'upserts': [for (final u in upserts) u.toJson()],
    'deletes': [for (final d in deletes) d.toJson()],
    'cursor': cursor,
  };
}

/// A parsed pull request: `{table, since?}`, mirroring the Convex
/// `sync:pullRecords` query args (`since` optional ⇒ full pull).
class PullRequest {
  const PullRequest({required this.table, required this.since});

  /// Parse and structurally validate the request body. Throws [PullRejection]
  /// (→ HTTP 400) on a malformed envelope.
  factory PullRequest.fromJson(final Map<String, dynamic> body) {
    final table = body['table'];
    if (table is! String || table.isEmpty) {
      throw const PullRejection('missing or invalid "table".');
    }
    return PullRequest(table: table, since: _sinceFromJson(body['since']));
  }

  final String table;
  final int? since; // null ⇒ full pull
}

/// Raised when a table is not pullable via `sync-pull` (fsrsCards, reviewEvents,
/// unknown table) or the body is malformed. The Function maps it to HTTP 400.
class PullRejection implements Exception {
  const PullRejection(this.message);

  final String message;

  @override
  String toString() => 'PullRejection: $message';
}

/// Read seam. The Function wires a `TablesDB`-backed implementation; tests wire
/// an in-memory fake. Both methods return every matching row (the store paginates
/// internally) filtered to `> since`, keyed by the trusted [userId].
abstract interface class PullStore {
  Future<List<LiveRecord>> listLiveSince(
    final String table,
    final String userId,
    final int? since,
  );

  Future<List<TombstoneRecord>> listTombstonesSince(
    final String table,
    final String userId,
    final int? since,
  );
}

/// Validate the table, read both states, and build the delta. Validation runs
/// **before** any store read (a forbidden table never queries), matching the
/// fail-closed shape of `sync-push`'s `applyPush`.
Future<PullDelta> pull(
  final PullStore store,
  final String userId,
  final PullRequest req,
) async {
  validatePullTable(req.table);
  final live = await store.listLiveSince(req.table, userId, req.since);
  final tombstones = await store.listTombstonesSince(req.table, userId, req.since);
  return buildPullDelta(since: req.since, live: live, tombstones: tombstones);
}

/// Enforce the "only the five descriptive tables are pullable" rule plus the two
/// named redirections. Mirrors `sync-push`'s `validatePushTable`; the Convex
/// `descriptiveTable` union excludes `fsrsCards`/`reviewEvents` identically.
void validatePullTable(final String table) {
  if (table == 'fsrsCards') {
    throw const PullRejection(
      'fsrsCards is derived server-side from reviewEvents and is pulled via the '
      'FSRS Function, not sync-pull.',
    );
  }
  if (table == 'reviewEvents') {
    throw const PullRejection(
      'reviewEvents is append-only and is pulled via the reviews Function, not '
      'sync-pull.',
    );
  }
  if (!descriptiveTables.contains(table)) {
    throw PullRejection('unsupported table: "$table".');
  }
}

/// Shape the delta and compute the high-water cursor. [live] and [tombstones]
/// are already filtered to `> since` by the store, so this is pure projection +
/// a max-reduce. Port of `pullRecords`' return arm, unioned across the two
/// tables: `highWater` reduces over both clocks (floored at `since`), and the
/// cursor is that high-water when anything changed, else the untouched `since`.
PullDelta buildPullDelta({
  required final int? since,
  required final List<LiveRecord> live,
  required final List<TombstoneRecord> tombstones,
}) {
  final upserts = [
    for (final r in live)
      PullUpsert(
        id: r.id,
        json: r.json,
        updatedAt: r.updatedAt,
        clientOpId: r.clientOpId,
      ),
  ];
  final deletes = [
    for (final t in tombstones)
      PullDelete(id: t.id, deletedAt: t.deletedAt, clientOpId: t.clientOpId),
  ];

  var highWater = since ?? 0;
  for (final r in live) {
    if (r.updatedAt > highWater) {
      highWater = r.updatedAt;
    }
  }
  for (final t in tombstones) {
    if (t.deletedAt > highWater) {
      highWater = t.deletedAt;
    }
  }

  final hasChanges = upserts.isNotEmpty || deletes.isNotEmpty;
  return PullDelta(
    upserts: upserts,
    deletes: deletes,
    cursor: hasChanges ? highWater : since,
  );
}

/// Parse the optional `since`: absent/null ⇒ full pull; an int (or integral num)
/// ⇒ that cursor; anything else ⇒ a malformed request.
int? _sinceFromJson(final Object? v) {
  if (v == null) {
    return null;
  }
  if (v is int) {
    return v;
  }
  if (v is num) {
    return v.toInt();
  }
  throw const PullRejection('invalid "since": expected an integer cursor.');
}
