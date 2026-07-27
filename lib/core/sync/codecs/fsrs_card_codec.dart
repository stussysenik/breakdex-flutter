/// FSRS card ⇐ [SyncRecord] codec — the provider-neutral **decode** for the
/// derived `fsrsCards` entity (task 4.6).
///
/// **Decode-only, by design.** Unlike `move_codec` / `combo_codec` (LWW, encode
/// + decode) and `review_codec` (append, encode + decode), an FSRS card is
/// *never pushed*: its scheduling state is a pure reduction of the entity's
/// `reviewEvents` log, derived server-side by the `reviews-append` Function using
/// the same `fsrs: ^2.0.1` package the client runs (Decision 7 / task 1.4). The
/// client only ever *pulls* the derived card, so this codec has no
/// `…ToSyncRecord` inverse — there is nothing to encode.
///
/// **What the derive carries.** The backend row (and so [SyncRecord.json], shaped
/// by `AppwriteSyncBackend._decodeFsrsCardRow`) holds only the reduced schedule:
/// `stability` / `difficulty` / `due` (ms-epoch int) / `state` (fsrs 1–3). It
/// deliberately does *not* carry `reps` / `lapses` / `lastReview`: the `fsrs`
/// 2.x `Card` has no reps/lapses fields (they are vestigial local columns, not
/// part of the math), and `lastReview` is reconstructable but not needed for
/// scheduling. So the decoded companion sets only the derived columns — on a
/// fresh insert the rest take their table defaults, and on an upsert the existing
/// local `reps` / `lapses` / `lastReview` are left untouched (Drift updates only
/// the columns a companion names).
library;

import 'package:drift/drift.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/sync/sync_backend.dart';

/// Decode a pulled `fsrsCard` [record] into an [FsrsCardsCompanion] over the
/// derived schedule fields. Identity is the `(entityId, entityType)` composite
/// PK, read from [SyncRecord.json] (not the composite `record.id`). `state`
/// crosses as the raw fsrs value (1=learning, 2=review, 3=relearning — a derived
/// card has folded ≥ 1 event, so it is never the DB-only `0`=new).
FsrsCardsCompanion fsrsCardFromSyncRecord(final SyncRecord record) {
  final json = record.json;
  return FsrsCardsCompanion(
    entityId: Value(json['entityId'] as String),
    entityType: Value(json['entityType'] as String),
    stability: Value((json['stability'] as num).toDouble()),
    difficulty: Value((json['difficulty'] as num).toDouble()),
    due: Value(
      DateTime.fromMillisecondsSinceEpoch((json['due'] as num).toInt(),
          isUtc: true),
    ),
    fsrsState: Value((json['state'] as num).toInt()),
  );
}
