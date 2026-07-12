/// Review ⇄ [SyncRecord] codec — the provider-neutral (de)serialization for the
/// **append-only** `reviewEvents` entity (task 4.5), shared by the backfill
/// (encode) and the dual-read merge (decode).
///
/// **Why this differs from `move_codec` / `combo_codec` (LWW).** A review is an
/// immutable event, not a mutable record: it is only ever appended, never
/// updated or deleted, and the backend dedupes replays by `clientOpId`
/// (idempotency index `(userId, clientOpId)`). So there is no LWW clock to
/// migrate — `reviewedAt` *is* the event time, and the review's own `id` is the
/// stable idempotency key. The wire shape carries only what the server-side FSRS
/// derive folds on: `(entityType, entityId, rating)` keyed by `reviewedAt`.
///
/// **Source of truth for the reviewed entity.** The FK columns (`moveId` /
/// `comboId`) are `onDelete: setNull`, so they vanish if the move/combo is later
/// deleted. The immutable snapshot columns (`entityIdSnapshot` / `entityType`,
/// added with the streaks redesign) survive that, so they are preferred; the FKs
/// are the legacy fallback for rows predating the snapshot. A row with neither
/// (a pre-snapshot review whose entity was since deleted) is genuinely
/// unencodable — [reviewToSyncRecord] returns `null` and the caller skips it.
library;

import 'package:drift/drift.dart';

import '../../database/database.dart';
import '../../models/learning_state.dart';
import '../sync_backend.dart';

/// Project a [Review] onto its provider-neutral append-only [SyncRecord], or
/// `null` when the reviewed entity cannot be identified (see the library note).
/// `clientOpId` is the review's own id — the natural idempotency key, so a
/// replay of the same event is a server-side no-op.
SyncRecord? reviewToSyncRecord(final Review r) {
  final entityId = r.entityIdSnapshot ?? r.moveId ?? r.comboId;
  if (entityId == null) return null;
  final entityType = r.entityType ?? (r.moveId != null ? 'move' : 'combo');
  return SyncRecord(
    id: r.id,
    type: SyncEntityType.reviewEvent,
    json: {
      'entityId': entityId,
      'entityType': entityType,
      // The backend keys FSRS on the rating's DB index (0=again … 3=easy), not
      // its string label; the enum's declaration order is that index.
      'rating': ReviewRating.fromString(r.rating).index,
    },
    updatedAt: r.reviewedAt,
    clientOpId: r.id,
  );
}

/// Decode a pulled `reviewEvent` [record] back into a [ReviewsCompanion] — the
/// inverse of [reviewToSyncRecord] over the fields the event carries. The event
/// log is intentionally minimal, so denormalized locals it never carried
/// (`entityDisplayName` / `entityCategory` / the `fsrsPre/PostState`) stay null,
/// and a MANUAL review round-trips as its entity's plain type — those are
/// on-device conveniences, not part of the canonical log.
///
/// The FK columns are left null (never reconstructed): the pulled entity may not
/// have arrived yet under its own independent cursor, so binding an FK here could
/// violate the constraint. `entityIdSnapshot` + `entityType` preserve the
/// entity's identity for stats without that risk.
ReviewsCompanion reviewFromSyncRecord(final SyncRecord record) {
  final json = record.json;
  final entityType = json['entityType'] as String;
  return ReviewsCompanion(
    id: Value(record.id),
    rating: Value(ReviewRating.values[(json['rating'] as num).toInt()].dbValue),
    reviewType: Value(
      entityType == 'combo' ? ReviewType.combo.dbValue : ReviewType.move.dbValue,
    ),
    reviewedAt: Value(record.updatedAt),
    entityIdSnapshot: Value(json['entityId'] as String),
    entityType: Value(entityType),
  );
}
