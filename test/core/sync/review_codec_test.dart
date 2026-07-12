/// Wave task 4.5 — `review_codec` append-only round-trip proof.
///
/// Unlike the LWW codecs, a review encodes to an immutable `reviewEvent`: the
/// reviewed entity comes from the delete-survivable snapshot (FK fallback), the
/// rating crosses as its DB index, `reviewedAt` is the clock, and the review's
/// own id is the `clientOpId`. A row with no identifiable entity encodes to
/// `null`. Pure — no DB.
library;

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/sync/codecs/review_codec.dart';
import 'package:breakdex/core/sync/sync_backend.dart';
import 'package:flutter_test/flutter_test.dart';

Review _review({
  final String id = 'r1',
  final String rating = 'GOOD',
  final String reviewType = 'MOVE',
  required final DateTime reviewedAt,
  final String? moveId,
  final String? comboId,
  final String? entityIdSnapshot,
  final String? entityType,
}) => Review(
  id: id,
  rating: rating,
  reviewType: reviewType,
  reviewedAt: reviewedAt,
  moveId: moveId,
  comboId: comboId,
  entityIdSnapshot: entityIdSnapshot,
  entityType: entityType,
);

void main() {
  final reviewedAt = DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);

  group('reviewToSyncRecord', () {
    test('snapshot is the source of truth; rating → index; id outside json', () {
      final rec = reviewToSyncRecord(
        _review(
          rating: 'EASY',
          moveId: 'm-stale',
          entityIdSnapshot: 'm1',
          entityType: 'move',
          reviewedAt: reviewedAt,
        ),
      )!;
      expect(rec.id, 'r1');
      expect(rec.type, SyncEntityType.reviewEvent);
      expect(rec.updatedAt, reviewedAt);
      expect(rec.clientOpId, 'r1');
      expect(rec.json, {
        'entityId': 'm1', // snapshot wins over the (stale) FK
        'entityType': 'move',
        'rating': 3, // EASY
      });
      expect(rec.json.containsKey('id'), isFalse);
    });

    test('every rating maps to its DB index', () {
      for (final (r, i) in [('AGAIN', 0), ('HARD', 1), ('GOOD', 2), ('EASY', 3)]) {
        final rec = reviewToSyncRecord(
          _review(rating: r, entityIdSnapshot: 'm1', entityType: 'move', reviewedAt: reviewedAt),
        )!;
        expect(rec.json['rating'], i, reason: r);
      }
    });

    test('FK fallback when snapshot is null: move vs combo', () {
      final asMove = reviewToSyncRecord(
        _review(moveId: 'm9', reviewedAt: reviewedAt),
      )!;
      expect(asMove.json['entityId'], 'm9');
      expect(asMove.json['entityType'], 'move');

      final asCombo = reviewToSyncRecord(
        _review(comboId: 'c9', reviewedAt: reviewedAt),
      )!;
      expect(asCombo.json['entityId'], 'c9');
      expect(asCombo.json['entityType'], 'combo');
    });

    test('null when the reviewed entity cannot be identified', () {
      expect(reviewToSyncRecord(_review(reviewedAt: reviewedAt)), isNull);
    });
  });

  group('reviewFromSyncRecord', () {
    SyncRecord event({
      final String id = 'r1',
      final String entityId = 'm1',
      final String entityType = 'move',
      final int rating = 2,
    }) => SyncRecord(
      id: id,
      type: SyncEntityType.reviewEvent,
      json: {'entityId': entityId, 'entityType': entityType, 'rating': rating},
      updatedAt: reviewedAt,
      clientOpId: id,
    );

    test('index → dbValue; reviewType derived; snapshot set; FK left null', () {
      final c = reviewFromSyncRecord(event(rating: 3, entityType: 'combo', entityId: 'c1'));
      expect(c.id.value, 'r1');
      expect(c.rating.value, ReviewRating.easy.dbValue);
      expect(c.reviewType.value, ReviewType.combo.dbValue);
      expect(c.reviewedAt.value, reviewedAt);
      expect(c.entityIdSnapshot.value, 'c1');
      expect(c.entityType.value, 'combo');
      // FK columns are never reconstructed (entity may not have arrived yet).
      expect(c.moveId.present, isFalse);
      expect(c.comboId.present, isFalse);
    });

    test('move event derives the move review type', () {
      final m = reviewFromSyncRecord(event(entityType: 'move'));
      expect(m.reviewType.value, ReviewType.move.dbValue);
    });
  });

  test('round-trip preserves the canonical fields', () {
    final original = _review(
      rating: 'HARD',
      entityIdSnapshot: 'm1',
      entityType: 'move',
      reviewedAt: reviewedAt,
    );
    final back = reviewFromSyncRecord(reviewToSyncRecord(original)!);
    expect(back.id.value, original.id);
    expect(back.rating.value, original.rating);
    expect(back.reviewedAt.value, original.reviewedAt);
    expect(back.entityIdSnapshot.value, 'm1');
    expect(back.entityType.value, 'move');
  });
}
