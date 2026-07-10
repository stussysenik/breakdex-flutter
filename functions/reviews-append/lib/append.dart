/// Pure, provider-neutral core for the `reviews-append` Appwrite Function.
/// Imports nothing from `dart_appwrite`, so the semantics — idempotent
/// append-only ingestion (ported from `convex/reviews.ts` `appendReviewEvents`)
/// plus event-triggered FSRS derivation — are unit-testable against an
/// in-memory [AppendStore] with no live backend, mirroring `sync-push`/`sync-pull`.
///
/// **Why append derives here (event-triggered, not pull-time).** The review log
/// is the source of truth; a card is a reduction of it that clients *pull, never
/// push* (Decision 7). Two placements were weighed:
///   * **pull-time** — derive inside a card-pull. Either recomputes every card
///     from the whole log on each pull (O(all events)/pull, and the delta cursor
///     can no longer be incremental), or caches on read and races concurrent
///     pulls writing the same card.
///   * **event-triggered** — derive right after append, for only the entities a
///     batch touched, reading only those entities' logs. FSRS math lives in
///     exactly one place; the card pull collapses to a plain `fsrsCards` delta
///     (identical mechanics to the shipped `sync-pull`), and "clients pull,
///     never push" holds by construction — the server writes the card at append
///     time; clients only ever read it.
/// Event-triggered is simpler end-to-end and is what this Function implements.
///
/// `userId` is always the trusted `x-appwrite-user-id` the Function stamps, not
/// a client-supplied field — every store read/write is scoped to it.
library;

import 'derive.dart';

/// A client-authored review event. Wire shape mirrors `convex/reviews.ts`
/// `reviewEventArg`: `localId` + `entityId` + `entityType` + `rating` +
/// ms-epoch `reviewedAt` + `clientOpId`. There are no deletes — the log is
/// append-only.
class ReviewEventOp {
  const ReviewEventOp({
    required this.localId,
    required this.entityId,
    required this.entityType,
    required this.rating,
    required this.reviewedAt,
    required this.clientOpId,
  });

  final String localId;
  final String entityId;
  final String entityType; // 'move' | 'combo'
  final int rating; // DB index: 0=again 1=hard 2=good 3=easy
  final int reviewedAt; // ms since epoch
  final String clientOpId;

  /// The entity this event schedules, identified as `(entityType, entityId)`.
  EntityKey get entity => EntityKey(entityType, entityId);
}

/// A `(entityType, entityId)` pair — the derivation unit and `fsrsCards` key.
class EntityKey {
  const EntityKey(this.entityType, this.entityId);

  final String entityType;
  final String entityId;

  @override
  bool operator ==(final Object other) =>
      other is EntityKey &&
      other.entityType == entityType &&
      other.entityId == entityId;

  @override
  int get hashCode => Object.hash(entityType, entityId);

  @override
  String toString() => '$entityType:$entityId';
}

/// A batched append request. Shape mirrors the Convex `reviews:appendReviewEvents`
/// mutation args (`{events: [...]}`) so the Phase 2 client transport marshals to
/// it unchanged.
class AppendRequest {
  const AppendRequest({required this.events});

  /// Parse and structurally validate the body. Throws [AppendRejection]
  /// (→ HTTP 400) on a malformed envelope or event — a client append is a
  /// trusted-shape contract, so a bad payload is the caller's error.
  factory AppendRequest.fromJson(final Map<String, dynamic> body) {
    final raw = body['events'];
    if (raw is! List) {
      throw const AppendRejection('missing or invalid "events" array.');
    }
    return AppendRequest(events: raw.map(_eventFromJson).toList());
  }

  final List<ReviewEventOp> events;
}

ReviewEventOp _eventFromJson(final Object? e) {
  if (e is! Map) {
    throw const AppendRejection('each event must be an object.');
  }
  final map = e.cast<String, dynamic>();
  final localId = map['localId'];
  final entityId = map['entityId'];
  final entityType = map['entityType'];
  final rating = map['rating'];
  final reviewedAt = map['reviewedAt'];
  final clientOpId = map['clientOpId'];
  if (localId is! String || localId.isEmpty) {
    throw const AppendRejection('event "localId" must be a non-empty string.');
  }
  if (entityId is! String || entityId.isEmpty) {
    throw const AppendRejection('event "entityId" must be a non-empty string.');
  }
  if (entityType is! String || entityType.isEmpty) {
    throw const AppendRejection('event "entityType" must be a non-empty string.');
  }
  if (rating is! int || rating < 0 || rating > 3) {
    throw const AppendRejection('event "rating" must be an int in 0..3.');
  }
  if (reviewedAt is! int) {
    throw const AppendRejection('event "reviewedAt" must be an int (ms epoch).');
  }
  if (clientOpId is! String || clientOpId.isEmpty) {
    throw const AppendRejection('event "clientOpId" must be a non-empty string.');
  }
  return ReviewEventOp(
    localId: localId,
    entityId: entityId,
    entityType: entityType,
    rating: rating,
    reviewedAt: reviewedAt,
    clientOpId: clientOpId,
  );
}

/// Outcome of an [applyAppend]: [appended] events inserted, [skipped] duplicates
/// (idempotent replay), [derived] distinct entities re-reduced, and [failed]
/// per-item store faults isolated so one bad row never aborts the batch
/// (hardened-template H.3).
class AppendResult {
  const AppendResult({
    this.appended = 0,
    this.skipped = 0,
    this.derived = 0,
    this.failed = 0,
  });

  final int appended;
  final int skipped;
  final int derived;
  final int failed;
}

/// Raised on a malformed request body/event. The Function maps it to HTTP 400.
/// An [Exception] (expected control flow), not an `Error`.
class AppendRejection implements Exception {
  const AppendRejection(this.message);

  final String message;

  @override
  String toString() => 'AppendRejection: $message';
}

/// Storage seam the pure core drives. Implemented over Appwrite TablesDB in
/// `main.dart`, and in-memory in tests. All keys are scoped to the trusted
/// `userId`.
abstract class AppendStore {
  /// Whether a `reviewEvents` row already exists for this `clientOpId` — the
  /// idempotency guard (Convex's `by_clientOpId` lookup).
  Future<bool> hasEvent(final String userId, final String clientOpId);

  /// Insert one immutable `reviewEvents` row under owner-only permissions.
  Future<void> insertEvent(final String userId, final ReviewEventOp event);

  /// All of an entity's events, ordered oldest→newest by `reviewedAt` — the
  /// exact input the FSRS reduce folds over. Must include events just inserted
  /// in this same request.
  Future<List<DerivableEvent>> listEventsForEntity(
    final String userId,
    final EntityKey entity,
  );

  /// Upsert the derived `fsrsCards` row (create or update) under owner-only
  /// permissions. Never client-pushed; only this derive writes it.
  Future<void> upsertCard(
    final String userId,
    final EntityKey entity,
    final DerivedCard card,
  );
}

/// Append [request]'s events idempotently, then re-derive every entity a *newly
/// appended* event touched. Duplicate events (seen `clientOpId`) are skipped and
/// never trigger a re-derive. Each event append and each entity derive is
/// isolated: a transient store fault increments [AppendResult.failed] and never
/// aborts the batch (H.3).
Future<AppendResult> applyAppend(
  final AppendStore store,
  final String userId,
  final AppendRequest request, {
  final DeriveConfig config = DeriveConfig.defaults,
  final void Function(String message)? onError,
}) async {
  var appended = 0;
  var skipped = 0;
  var failed = 0;
  final dirty = <EntityKey>{};

  for (final event in request.events) {
    try {
      if (await store.hasEvent(userId, event.clientOpId)) {
        skipped++;
        continue;
      }
      await store.insertEvent(userId, event);
      appended++;
      dirty.add(event.entity);
    } on Object catch (e) {
      failed++;
      onError?.call('append failed for ${event.clientOpId}: $e');
    }
  }

  var derived = 0;
  for (final entity in dirty) {
    try {
      final events = await store.listEventsForEntity(userId, entity);
      final card = deriveCard(entity.entityId, events, config: config);
      if (card == null) {
        continue;
      }
      await store.upsertCard(userId, entity, card);
      derived++;
    } on Object catch (e) {
      failed++;
      onError?.call('derive failed for $entity: $e');
    }
  }

  return AppendResult(
    appended: appended,
    skipped: skipped,
    derived: derived,
    failed: failed,
  );
}
