/// Wave task 4.6 — `fsrs_card_codec` decode proof.
///
/// The derived card is **never pushed**, so the codec is decode-only: a pulled
/// `fsrsCard` [SyncRecord] → [FsrsCardsCompanion] over the derived schedule
/// fields (`stability` / `difficulty` / `due` / `state`). `reps` / `lapses` /
/// `lastReview` are deliberately NOT set — the derive does not carry them, so on
/// upsert Drift leaves the existing local values untouched. Pure — no DB.
library;

import 'package:breakdex/core/sync/codecs/fsrs_card_codec.dart';
import 'package:breakdex/core/sync/sync_backend.dart';
import 'package:flutter_test/flutter_test.dart';

SyncRecord _card({
  final String entityId = 'm1',
  final String entityType = 'move',
  final num stability = 12.5,
  final num difficulty = 6.0,
  final int dueMs = 1700000500000,
  final int state = 2,
  final int updatedAtMs = 1700000000000,
}) => SyncRecord(
  id: '$entityType:$entityId',
  type: SyncEntityType.fsrsCard,
  json: {
    'entityId': entityId,
    'entityType': entityType,
    'stability': stability,
    'difficulty': difficulty,
    'due': dueMs,
    'state': state,
    'lastEventOpId': 'op-last',
  },
  updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs, isUtc: true),
  clientOpId: 'op-last',
);

void main() {
  group('fsrsCardFromSyncRecord', () {
    test('maps the derived schedule fields; identity from json', () {
      final c = fsrsCardFromSyncRecord(_card());
      expect(c.entityId.value, 'm1');
      expect(c.entityType.value, 'move');
      expect(c.stability.value, 12.5);
      expect(c.difficulty.value, 6.0);
      expect(c.due.value,
          DateTime.fromMillisecondsSinceEpoch(1700000500000, isUtc: true));
      expect(c.due.value.isUtc, isTrue);
      expect(c.fsrsState.value, 2);
    });

    test('never sets reps/lapses/lastReview (not carried by the derive)', () {
      final c = fsrsCardFromSyncRecord(_card());
      expect(c.reps.present, isFalse);
      expect(c.lapses.present, isFalse);
      expect(c.lastReview.present, isFalse);
    });

    test('combo cards decode under their own type', () {
      final c = fsrsCardFromSyncRecord(_card(entityId: 'c9', entityType: 'combo'));
      expect(c.entityId.value, 'c9');
      expect(c.entityType.value, 'combo');
    });

    test('state crosses as the raw fsrs value (1..3, never DB-only 0)', () {
      for (final s in [1, 2, 3]) {
        expect(fsrsCardFromSyncRecord(_card(state: s)).fsrsState.value, s);
      }
    });

    test('integer-typed doubles coerce (JSON may deliver stability as int)', () {
      final c = fsrsCardFromSyncRecord(_card(stability: 3, difficulty: 5));
      expect(c.stability.value, 3.0);
      expect(c.difficulty.value, 5.0);
    });
  });
}
