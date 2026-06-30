/// Provider-agnostic **metadata** sync contract.
///
/// This is the Flutter app's single door to the canonical metadata backend
/// (Convex). It is deliberately distinct from [AssetStorageProvider] in
/// `cloud_provider.dart`: that contract moves *blobs* (videos); this one syncs
/// *records* (moves, combos, reviews, decks). Video bytes never flow through
/// here — records carry only pointers (Drive file id / object key) + content
/// hash.
///
/// **Safety posture** (see `openspec/changes/add-convex-sync-backend`):
/// callers depend on this interface, not on Convex. Drift stays the
/// authoritative on-device store; a [SyncBackend] is a shadow copy per entity
/// until that entity's two-way reconcile is verified. Nothing here deletes or
/// mutates local rows — deletes propagate as [SyncTombstone]s, never
/// hard-deletes.
library;

/// The metadata entity types that sync through a [SyncBackend].
///
/// [reviewEvent] is **append-only** (each rating is an immutable event).
/// [fsrsCard] is **derived** server-side by reducing the review-event log, so
/// clients pull/subscribe it but do not [SyncBackend.push] it directly — its
/// scheduling state must never be last-writer-wins overwritten.
enum SyncEntityType {
  move,
  combo,
  comboMove,
  reviewEvent,
  fsrsCard,
  deck,
  deckMove,
}

/// An immutable upsert payload for one record.
///
/// [json] is the generic, provider-neutral representation of the record (DOP:
/// data is plain, not hidden inside an opaque object). [updatedAt] drives
/// last-writer-wins reconciliation for descriptive records. [clientOpId] makes
/// a push idempotent: replaying the same op never double-applies.
class SyncRecord {
  const SyncRecord({
    required this.id,
    required this.type,
    required this.json,
    required this.updatedAt,
    required this.clientOpId,
  });

  /// Stable local row id; identity is preserved across the sync boundary.
  final String id;
  final SyncEntityType type;
  final Map<String, dynamic> json;
  final DateTime updatedAt;

  /// Idempotency key for this write. Same key ⇒ at-most-once apply.
  final String clientOpId;
}

/// An immutable soft-delete marker. Removal is a tombstone, never a
/// hard-delete, so user state is recoverable and reconcilable.
class SyncTombstone {
  const SyncTombstone({
    required this.id,
    required this.type,
    required this.deletedAt,
    required this.clientOpId,
  });

  final String id;
  final SyncEntityType type;
  final DateTime deletedAt;
  final String clientOpId;
}

/// A batch of changes for one entity type, returned by [SyncBackend.pull] and
/// emitted by [SyncBackend.subscribe].
///
/// [cursor] is the high-water mark to pass to the next [SyncBackend.pull] so
/// the client only fetches what changed since last reconcile.
class SyncDelta {
  const SyncDelta({
    required this.upserts,
    required this.deletes,
    this.cursor,
  });

  final List<SyncRecord> upserts;
  final List<SyncTombstone> deletes;
  final DateTime? cursor;

  bool get isEmpty => upserts.isEmpty && deletes.isEmpty;
}

/// Storage-agnostic metadata sync contract.
///
/// Implementations are the *only* code that touches a concrete backend client
/// (e.g. the community `convex_flutter` package, or Convex's HTTP API as a
/// fallback). Swapping Convex Cloud for a self-hosted Convex — or another
/// provider entirely — changes only the implementation, never the callers.
abstract interface class SyncBackend {
  /// Machine-readable provider id, e.g. `'convex'`.
  String get providerType;

  /// Push client-authored changes for [type].
  ///
  /// Upserts and deletes are idempotent via [SyncRecord.clientOpId] /
  /// [SyncTombstone.clientOpId]. Do **not** push [SyncEntityType.fsrsCard];
  /// derived FSRS state is computed server-side from
  /// [SyncEntityType.reviewEvent]s.
  Future<void> push(
    final SyncEntityType type, {
    final List<SyncRecord> upserts = const [],
    final List<SyncTombstone> deletes = const [],
  });

  /// Pull everything for [type] that changed since [since] (null = full pull).
  Future<SyncDelta> pull(
    final SyncEntityType type, {
    final DateTime? since,
  });

  /// Reactive stream of deltas for [type] — the basis of eventual-realtime
  /// sync across the app, web, and future native clients.
  Stream<SyncDelta> subscribe(final SyncEntityType type);
}
